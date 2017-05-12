package Catalyst::Plugin::Charsets::Japanese;
use strict;

use base qw/Class::Data::Inheritable/;
use Jcode;
use NEXT;

__PACKAGE__->mk_classdata('charsets');
__PACKAGE__->charsets( Catalyst::Plugin::Charsets::Japanese::Handler->new );

our $VERSION = '0.06';

sub finalize {
    my $c = shift;
    unless ( $c->response->body and not ref $c->response->body ) {
        return $c->NEXT::finalize;
    }
    unless ( $c->response->content_type =~ /^text|xml$|javascript$/ ) {
        return $c->NEXT::finalize;
    }

    my $content_type = $c->response->content_type;
    $content_type =~ s/\;\s*$//;
    $content_type =~ s/\;*\s*charset\s*\=.*$//i;
    $content_type .= sprintf("; charset=%s", $c->charsets->out->name );
    $c->response->content_type($content_type);

    my $body = $c->response->body;

    if( $c->charsets->in->name eq 'UTF-8' && utf8::is_utf8($body) ) {
        utf8::encode($body);
    }

    my $in  = $c->charsets->in->abbreviation;
    my $out = $c->charsets->out->method;
    $body = Jcode->new($body, $in)->$out;

    $c->response->body($body);

    $c->NEXT::finalize;
}

sub prepare_parameters {
    my $c = shift;
    $c->NEXT::prepare_parameters;

    my $in  = $c->charsets->in->method;
    my $out = $c->charsets->out->abbreviation;

    for my $value ( values %{ $c->request->{parameters} } ) {
        if( ref $value && ref $value ne 'ARRAY' ) {
            next;
        }
        for ( ref($value) ? @{$value} : $value ) {
            $_ = Jcode->new($_, $out)->h2z->$in;
            utf8::decode($_) if $c->charsets->in->name eq 'UTF-8';
        }
    }
}

sub setup {
    my $self = shift;
    $self->NEXT::setup(@_);
    my $setting = $self->config->{charsets} || 'UTF-8' ;
    if(ref $setting eq 'HASH') {
        $self->charsets->set_inner($setting->{in});
        $self->charsets->set_outer($setting->{out})
    } else {
        $self->charsets->set_inner($setting);
        $self->charsets->set_outer($setting);
    }
    if($self->debug){    
    $self->log->debug($self->charsets->in->name." is selected for inner code.");
    $self->log->debug($self->charsets->out->name." is selected for outer code.");
    }
}

package Catalyst::Plugin::Charsets::Japanese::Handler;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/in out/);

sub new { bless {}, $_[0] }

sub set_inner {
    my($self, $code) = @_;
    $self->in(Catalyst::Plugin::Charsets::Japanese::Charset->new($code));
}
sub set_outer {
    my($self, $code) = @_;
    $self->out(Catalyst::Plugin::Charsets::Japanese::Charset->new($code));
}

sub name {
    my $self = shift;
    return $self->in->name;
}

sub abbreviation {
    my $self = shift;
    return $self->in->abbreviation;
}

sub method {
    my $self = shift;
    return $self->in->method;
}

package Catalyst::Plugin::Charsets::Japanese::Charset;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/name abbreviation method/);

my @TYPES = (
    [qw/UTF-8     utf8/],
    [qw/EUC-JP    euc/ ],
    [qw/Shift_JIS sjis/],
);

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;
    my $code = shift;
    foreach my $type ( @TYPES ) {
        foreach ( @$type ) {
            if( lc($code) eq lc($_) ) {
                $self->name($type->[0]);
                $self->abbreviation($type->[1]);
                $self->method($type->[1]);
                return;
            }
        }
    }
    $self->_croak("wrong charset detected.");
}

sub _croak {
    my($self, $msg) = @_;
    require Carp; Carp::croak($msg);
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Charsets::Japanese - Japanese specific charsets handler

=head1 SYNOPSIS

    use Catalyst 'Charsets::Japanese';

    # set charset
    MyApp->config->{charsets} = 'UTF-8';

    # you can set two charsets.
    # one is for inner, another is for output response.

    MyApp->config->{charsets} = {
        in  => 'EUC-JP',
        out => 'Shift_JIS',
    };

=head1 DESCRIPTION

Japanese usually use the charsets, UTF-8, EUC-JP, and Shift_JIS,
when they develop web applications.
This module allows you to deal with things related to Japanese charset automatically.

=head1 charsets

This plugin implements 'charsets' accessor to context object.

    sub default : Private {
        my( $self, $c ) = @_;

        # charset's name. UTF-8, EUC-JP, Shift_JIS
        my $inner_charset = $c->charsets->in->name;

        # charset's abbreviation. utf8, euc, shiftjis
        my $inner_abbrev  = $c->charsets->in->abbreviation;

        # Jcode method's name. utf8, euc, sjis
        my $inner_method  = $c->charsets->in->method;

        # and you can get information about charset for output response.
        my $outer_charset = $c->charsets->out->name;
    }

=head1 SEE ALSO

L<Jcode>

L<Catalyst>

L<Catalyst::Plugin::Charsets::Japanese::Nihongo.pod>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

