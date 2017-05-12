package BusyBird::Input::Generator;
use v5.8.0;
use strict;
use warnings;
use DateTime;
use BusyBird::DateTime::Format;
use Data::UUID;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        screen_name => defined($args{screen_name}) ? $args{screen_name} : "",
        id_gen => Data::UUID->new,
    }, $class;
    return $self;
}

sub generate {
    my ($self, %args) = @_;
    my $text = defined($args{text}) ? $args{text} : "";
    my $level = defined($args{level}) ? $args{level} : 0;
    my $cur_time = DateTime->now;
    my $status = +{
        id => $self->_generate_id(),
        text => $text,
        created_at => BusyBird::DateTime::Format->format_datetime($cur_time),
        user => {
            screen_name => $self->{screen_name},
        },
        busybird => {
            status_permalink => ""
        }
    };
    if(defined $level) {
        $status->{busybird}{level} = $level + 0;
    }
    return $status;
}

sub _generate_id {
    my ($self) = @_;
    my $namespace = $self->{screen_name};
    my $uuid = $self->{id_gen}->create_str;
    return qq{busybird://$namespace/$uuid};
    ## $cur_time = DateTime->now if not defined($cur_time);
    ## my $cur_epoch = $cur_time->epoch;
    ## if($self->{last_epoch} != $cur_epoch) {
    ##     $self->{next_sequence_number} = 0;
    ## }
    ## my $id = qq{busybird://$namespace/$cur_epoch/$self->{next_sequence_number}};
    ## $self->{next_sequence_number}++;
    ## $self->{last_epoch} = $cur_epoch;
    ## return $id;
}

1;
__END__

=pod

=head1 NAME

BusyBird::Input::Generator - status generator

=head1 SYNOPSIS

    use BusyBird::Input::Generator;
    
    my $gen = BusyBird::Input::Generator->new(screen_name => "toshio_ito");
    my $status = $gen->generate(text => "Hello, world!");

=head1 DESCRIPTION

L<BusyBird::Input::Generator> generates status objects.
It is useful for injecting arbitrary messages into your timelines,
or just for debugging purposes.

=head2 Features

=over

=item *

It automatically generates and sets the IDs of generated statuses.

=item *

It automatically sets the timestamps of generated statuses.

=back

=head1 CLASS METHODS

=head2 $gen = BusyBird::Input::Generator->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<screen_name> => STR (optional, default: "")

The C<user.screen_name> field of the statuses to be generated.

=back

=head1 OBJECT METHODS

=head2 $status = $gen->generate(%args)

Generates a status object.
See L<BusyBird::Manual::Status> for format of the status object.

Fields in C<%args> are:

=over

=item C<text> => STR (optional, default: "")

The C<text> field of the status. It must be a text string, not a binary (octet) string.

=item C<level> => INT (optional, default: 0)

The C<busybird.level> field of the status.

=back

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut



