package Catmandu::Exporter::Template;

use Catmandu::Sane;
use Catmandu::Util qw(is_string);
use Catmandu;
use Template;
use Storable qw(freeze);
use Moo;
use namespace::clean;

our $VERSION = '0.12';

with 'Catmandu::Exporter';

my $TT_INSTANCES = {};

my $XML_DECLARATION = qq(<?xml version="1.0" encoding="UTF-8"?>\n);

my $ADD_TT_EXT = sub {
    my $tmpl = $_[0];
    is_string($tmpl) && $tmpl !~ /\.\w{2,4}$/ ? "$tmpl.tt" : $tmpl;
};

my $OWN_OPTS = {
    map {($_ => 1)}
        qw(
        log_category
        autocommit
        count
        file
        fh
        xml
        template
        template_before
        template_after
        )
};

has xml             => (is => 'ro');
has template_before => (is => 'ro', coerce => $ADD_TT_EXT);
has template        => (is => 'ro', coerce => $ADD_TT_EXT, required => 1);
has template_after => (is => 'ro',   coerce   => $ADD_TT_EXT);
has _tt_opts       => (is => 'lazy', init_arg => undef);
has _tt            => (is => 'lazy', init_arg => undef);
has _before_done   => (is => 'rw', init_arg => undef);

sub BUILD {
    my ($self, $opts) = @_;
    my $tt_opts = $self->_tt_opts;
    for my $key (keys %$opts) {
        $tt_opts->{uc $key} = $opts->{$key} unless $OWN_OPTS->{$key};
    }
}

sub _build__tt_opts {
    +{
        ENCODING     => 'utf8',
        ABSOLUTE     => 1,
        RELATIVE     => 1,
        ANYCASE      => 0,
        INCLUDE_PATH => Catmandu->root,
    };
}

sub _build__tt {
    my ($self) = @_;
    my $opts = $self->_tt_opts;

    my $instance_key = do {
        local $Storable::canonical = 1;
        freeze($opts);
    };
    if (my $instance = $TT_INSTANCES->{$instance_key}) {
        return $instance;
    }

    my $vars = $opts->{VARIABLES} ||= {};
    $vars->{_root}   = Catmandu->root;
    $vars->{_config} = Catmandu->config;
    local $Template::Stash::PRIVATE = 0;
    $TT_INSTANCES->{$instance_key} = Template->new(%$opts);
}

sub _process {
    my ($self, $tmpl, $data) = @_;
    unless ($self->_tt->process($tmpl, $data || {}, $self->fh)) {
        my $msg = "Template error";
        $msg .= ": " . $self->_tt->error->info if $self->_tt->error;
        Catmandu::Error->throw($msg);
    }
}

sub add {
    my ($self, $data) = @_;
    unless ($self->_before_done) {
        $self->fh->print($XML_DECLARATION) if $self->xml;
        $self->_process($self->template_before) if $self->template_before;
        $self->_before_done(1);
    }
    $self->_process($self->template, $data);
}

sub commit {
    my ($self) = @_;
    $self->_process($self->template_after) if $self->template_after;
}

=head1 NAME

Catmandu::Exporter::Template - a TT2 Template exporter in Catmandu style

=head1 SYNOPSIS

    # From the command line
    echo '{"colors":["red","green","blue"]}' | 
        catmandu convert JSON to Template --template `pwd`/xml.tt

    where xml.tt like:

    <colors>
    [% FOREACH c IN colors %]
       <color>[% c %]</color>
    [% END %]
    </colors>

    # From perl
    use Catmandu::Exporter::Template;

    my $exporter = Catmandu::Exporter::Template->new(
                fix => 'myfix.txt'
                xml => 1,
                template_before => '<path>/header.xml' ,
                template => '<path>/record.xml' ,
                template_after => '<path>/footer.xml' ,
           );

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    $exporter->commit; # trigger the template_after

    printf "exported %d objects\n" , $exporter->count;

=head1 DESCRIPTION

This L<Catmandu::Exporter> can be used to export records using
L<Template Toolkit|Template::Manual>. If you are new to Catmandu
see L<Catmandu::Tutorial>.

=head1 CONFIGURATION

=over

=item template

Required. Must contain path to the template.

=item xml

Optional. Value: 0 or 1. Prepends xml header to the template.

=item template_before

Optional. Prepend output to the export.

=item template_after

Optional. Append output to the export.

=item fix

Optional. Apply Catmandu fixes while exporting.

=item [Template Toolkit configuration options]

You can also pass all Template Toolkit configuration options.

=back

=head1 SEE ALSO

L<Catmandu::Exporter>, L<Template>

=cut

1;
