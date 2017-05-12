package BusyBird::Config;
use v5.8.0;
use strict;
use warnings;
use Carp;
use BusyBird::Log qw(bblog);
use BusyBird::SafeData qw(safed);
use BusyBird::Util qw(config_file_path);
use URI::Escape qw(uri_escape);
use Encode ();
use Tie::IxHash;
use BusyBird::StatusStorage::SQLite;
use File::ShareDir ();

my %_DEFAULTS = ();

$_DEFAULTS{timeline} = {
    time_zone => sub { "local" },
    time_format => sub { '%x (%a) %X %Z' },
    time_locale => sub { $ENV{LC_TIME} or "C" },
    post_button_url => sub { "https://twitter.com/intent/tweet" },

    status_permalink_builder => sub { return sub {
        my ($status) = @_;
        my $ss = safed($status);
        my $permalink_in_status = $ss->val(qw(busybird status_permalink));
        return $permalink_in_status if defined $permalink_in_status;
        my $id =   $ss->val(qw(busybird original id))
                || $ss->val(qw(busybird original id_str))
                || $ss->val("id")
                || $ss->val("id_str");
        my $username = $ss->val(qw(user screen_name));
        if(defined($id) && defined($username) && $id =~ /^\d+$/) {
            return qq{https://twitter.com/$username/status/$id};
        }
        return undef;
    } },

    urls_entity_url_builder => sub { sub { my ($text, $entity) = @_; return $entity->{url} }},
    urls_entity_text_builder => sub { sub { my ($text, $entity) = @_; return $entity->{display_url} }},
    
    media_entity_url_builder => sub { sub { my ($text, $entity) = @_; return $entity->{url} } },
    media_entity_text_builder => sub { sub { my ($text, $entity) = @_; return $entity->{display_url} }},
    
    user_mentions_entity_url_builder => sub { sub {
        my ($text, $entity, $status) = @_;
        my $screen_name = $entity->{screen_name};
        $screen_name = "" if not defined $screen_name;
        return qq{https://twitter.com/$screen_name};
    }},
    user_mentions_entity_text_builder => sub { sub { my $text = shift; return $text }},
    
    hashtags_entity_url_builder => sub { sub {
        my ($text, $entity, $status) = @_;
        my $query_hashtag = uri_escape('#' . Encode::encode('utf8', $entity->{text}));
        return qq{https://twitter.com/search?q=$query_hashtag&src=hash};
    }},
    hashtags_entity_text_builder => sub { sub { my $text = shift; return $text }},
    
    timeline_web_notifications => sub { 'simple' },
    hidden => sub { 0 },

    attached_image_urls_builder => sub {
        return sub {
            my ($status) = @_;
            tie my %url_set, "Tie::IxHash";
            my $ss = safed($status);
            my @entities = map { $ss->array($_, "media") } qw(entities extended_entities);
            foreach my $entity (@entities) {
                my $sentity = safed($entity);
                my $url = $sentity->val("media_url");
                my $type = $sentity->val("type");
                if(defined($url) && (!defined($type) || lc($type) eq "photo")) {
                    $url_set{$url} = 1 if defined $url;
                }
            }
            return keys %url_set;
        };
    },
    attached_image_max_height => sub { 360 },
    attached_image_show_default => sub { "hidden" },
    acked_statuses_load_count => sub { 20 },
    default_level_threshold => sub { 0 },
};

$_DEFAULTS{global} = {
    %{$_DEFAULTS{timeline}},

    default_status_storage => sub {
        BusyBird::StatusStorage::SQLite->new(path => config_file_path("statuses.sqlite3"));
    },
    
    sharedir_path => sub { File::ShareDir::dist_dir("BusyBird") },
    timeline_list_pager_entry_max => sub { 7 },
    timeline_list_per_page => sub { 30 },
};

sub new {
    my ($class, %args) = @_;
    my $type = $args{type};
    croak "type parameter is mandatory" if not defined $type;
    my $default_generators = $_DEFAULTS{$type};
    croak "Unknown config type: $type" if not defined $default_generators;
    croak "with_default parameter is mandatory" if not defined $args{with_default};
    my $self = bless {
        default_generators => $default_generators,
        with_default => $args{with_default},
        config => {},
    }, $class;
    return $self;
}

sub get_config {
    my ($self, $key) = @_;
    croak "key parameter is mandatory" if not defined $key;
    return $self->{config}{$key} if exists $self->{config}{$key};
    return undef if !$self->{with_default};
    
    my $gen = $self->{default_generators}{$key};
    return undef if not defined $gen;
    my $value = $gen->();
    $self->set_config($key, $value);
    return $value;
}

sub set_config {
    my ($self, %configs) = @_;
    foreach my $key (keys %configs) {
        if(!exists($self->{default_generators}{$key})) {
            bblog("warn", "Unknown config parameter: $key");
        }
        $self->{config}{$key} = $configs{$key};
    }
}

1;
__END__

=pod

=head1 NAME

BusyBird::Config - configuration holder for BusyBird

=head1 DESCRIPTION

B<< This is an internal module. End-users should not use it. >>

L<BusyBird::Config> is a simple configuration holder for L<BusyBird>.

=over

=item *

It emits warning via L<BusyBird::Log> if unknown configuration parameter is set.
This helps users find typo.

=item *

If C<with_default> option is enabled, it lazily creates and returns the default value when C<get_config()> is called.

=back

=head1 CLASS METHODS

=head2 $con = BusyBird::Config->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<type> => STR (mandatory)

Type of the configuration. Either C<"global"> or C<"timeline">.

=item C<with_default> => BOOL (mandatory)

If set to true, it lazily creates and returns the default value when C<get_config()> is called on a known but not-yet-set parameter.

=back

=head1 OBJECT METHODS

=head2 $param = $con->get_config($key)

Returns the value of the config parameter named C<$key>.

If the value for C<$key> is already set by C<set_config()> method, it returns that value.

Otherwise, if C<with_default> option is enabled and the default value for C<$key> is prepared, it returns that value.

Otherwise it returns C<undef>.

=head2 $con->set_config($key1 => $value1, $key2 => $value2 ...)

Set config parameters.

If some C<$key> is unknown for this C<type> of C<$con>, it emits warning via L<BusyBird::Log>.

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut

