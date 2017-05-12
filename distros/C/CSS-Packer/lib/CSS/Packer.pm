package CSS::Packer;

use 5.008009;
use warnings;
use strict;
use Carp;
use Regexp::RegGrp;

our $VERSION            = '2.03';

our @COMPRESS           = ( 'minify', 'pretty' );
our $DEFAULT_COMPRESS   = 'pretty';

our @BOOLEAN_ACCESSORS = (
    'no_compress_comment',
    'remove_copyright'
);

our @COPYRIGHT_ACCESSORS = (
    'copyright',
    'copyright_comment'
);

our $COPYRIGHT_COMMENT  = '\/\*((?>[^*]|\*[^/])*copyright(?>[^*]|\*[^/])*)\*\/';

our $DICTIONARY     = {
    'STRING1'   => qr~"(?>(?:(?>[^"\\]+)|\\.|\\"|\\\s)*)"~,
    'STRING2'   => qr~'(?>(?:(?>[^'\\]+)|\\.|\\'|\\\s)*)'~
};

our $WHITESPACES    = '\s+';

our $RULE           = '([^{};]+)\{([^{}]*)\}';

our $URL            = 'url\(\s*(' . $DICTIONARY->{STRING1} . '|' . $DICTIONARY->{STRING2} . '|[^\'"\s]+?)\s*\)';

our $IMPORT         = '\@import\s+(' . $DICTIONARY->{STRING1} . '|' . $DICTIONARY->{STRING2} . '|' . $URL . ')([^;]*);';

our $MEDIA          = '\@media([^{}]+)\{((?:' . $IMPORT . '|' . $RULE . '|' . $WHITESPACES . ')+)\}';

our $DECLARATION    = '((?>[^;:]+)):(?<=:)((?>[^;]*))(?:;|\s*$)';

our $COMMENT        = '(\/\*[^*]*\*+([^/][^*]*\*+)*\/)';

our $PACKER_COMMENT = '\/\*\s*CSS::Packer\s*(\w+)\s*\*\/';

our $CHARSET        = '^(\@charset)\s+(' . $DICTIONARY->{STRING1} . '|' . $DICTIONARY->{STRING2} . ');';

our @REGGRPS        = ( 'whitespaces', 'url', 'import', 'declaration', 'rule', 'content_value', 'mediarules', 'global' );

# --------------------------------------------------------------------------- #

{
    no strict 'refs';

    foreach my $reggrp ( @REGGRPS ) {
        next if defined *{ __PACKAGE__ . '::reggrp_' . $reggrp }{CODE};

        *{ __PACKAGE__ . '::reggrp_' . $reggrp } = sub {
            my ( $self ) = shift;

            return $self->{ '_reggrp_' . $reggrp };
        };
    }

    foreach my $field ( @BOOLEAN_ACCESSORS ) {
        next if defined *{ __PACKAGE__ . '::' . $field }{CODE};

        *{ __PACKAGE__ . '::' . $field} = sub {
            my ( $self, $value ) = @_;

            $self->{'_' . $field} = $value ? 1 : undef if ( defined( $value ) );

            return $self->{'_' . $field};
        };
    }

    foreach my $field ( @COPYRIGHT_ACCESSORS ) {
        $field = '_' . $field if ( $field eq 'copyright_comment' );
        next if defined *{ __PACKAGE__ . '::' . $field }{CODE};

        *{ __PACKAGE__ . '::' . $field} = sub {
            my ( $self, $value ) = @_;

            if ( defined( $value ) and not ref( $value ) ) {
                $value =~ s/^\s*|\s*$//gs;
                $self->{'_' . $field} = $value;
            }

            my $ret = '';

            if ( $self->{'_' . $field} ) {
                $ret = '/* ' . $self->{'_' . $field} . ' */' . "\n";
            }

            return $ret;
        };
    }
}

sub compress {
    my ( $self, $value ) = @_;

    if ( defined( $value ) ) {
        if ( grep( $value eq $_, @COMPRESS ) ) {
            $self->{_compress} = $value;
        }
        elsif ( ! $value ) {
            $self->{_compress} = undef;
        }
    }

    $self->{_compress} ||= $DEFAULT_COMPRESS;

    return $self->{_compress};
}

# these variables are used in the closures defined in the init function
# below - we have to use globals as using $self within the closures leads
# to a reference cycle and thus memory leak, and we can't scope them to
# the init method as they may change. they are set by the minify sub
our $reggrp_url;
our $reggrp_declaration;
our $reggrp_mediarules;
our $reggrp_content_value;
our $global_compress;

sub init {
    my $class   = shift;
    my $self    = {};

    bless( $self, $class );

    $self->{content_value}->{reggrp_data} = [
        {
            regexp      => $DICTIONARY->{STRING1}
        },
        {
            regexp      => $DICTIONARY->{STRING2}
        },
        {
            regexp      => qr~([\w-]+)\(\s*([\w-]+)\s*\)~,
            replacement => sub {
                return $_[0]->{submatches}->[0] . '(' . $_[0]->{submatches}->[0] . ')';
            }
        },
        {
            regexp      => $WHITESPACES,
            replacement => ''
        }
    ];

    $self->{whitespaces}->{reggrp_data} = [
        {
            regexp      => $WHITESPACES,
            replacement => ''
        }
    ];

    $self->{url}->{reggrp_data} = [
        {
            regexp      => $URL,
            replacement => sub {
                my $url  = $_[0]->{submatches}->[0];

                return 'url(' . $url . ')';
            }
        }
    ];

    $self->{import}->{reggrp_data} = [
        {
            regexp      => $IMPORT,
            replacement => sub {
                my $submatches  = $_[0]->{submatches};
                my $url         = $submatches->[0];
                my $mediatype   = $submatches->[2];

				my $compress = $global_compress;
                $reggrp_url->exec( \$url );

                $mediatype =~ s/^\s*|\s*$//gs;
                $mediatype =~ s/\s*,\s*/,/gsm;

                return '@import ' . $url . ( $mediatype ? ( ' ' . $mediatype ) : '' ) . ';' . ( $compress eq 'pretty' ? "\n" : '' );
            }
        }
    ];

    $self->{declaration}->{reggrp_data} = [
        {
            regexp      => $DECLARATION,
            replacement => sub {
                my $submatches  = $_[0]->{submatches};
                my $key         = $submatches->[0];
                my $value       = $submatches->[1];

				my $compress = $global_compress;

                $key    =~ s/^\s*|\s*$//gs;
                $value  =~ s/^\s*|\s*$//gs;

                if ( $key eq 'content' ) {
                    $reggrp_content_value->exec( \$value );
                }
                else {
                    $value =~ s/\s*,\s*/,/gsm;
                    $value =~ s/\s+/ /gsm;
                }

                return '' if ( not $key or $value eq '' );

                return $key . ':' . $value . ';' . ( $compress eq 'pretty' ? "\n" : '' );
            }
        }
    ];

    $self->{rule}->{reggrp_data} = [
        {
            regexp      => $RULE,
            replacement => sub {
                my $submatches  = $_[0]->{submatches};
                my $selector    = $submatches->[0];
                my $declaration = $submatches->[1];

				my $compress = $global_compress;

                $selector =~ s/^\s*|\s*$//gs;
                $selector =~ s/\s*,\s*/,/gsm;
                $selector =~ s/\s+/ /gsm;

                $declaration =~ s/^\s*|\s*$//gs;

                $reggrp_declaration->exec( \$declaration );

                my $store = $selector . '{' . ( $compress eq 'pretty' ? "\n" : '' ) . $declaration . '}' .
                    ( $compress eq 'pretty' ? "\n" : '' );

                $store = '' unless ( $selector or $declaration );

                return $store;
            }
        }
    ];

    $self->{mediarules}->{reggrp_data} = [
        @{$self->{import}->{reggrp_data}},
        @{$self->{rule}->{reggrp_data}},
        @{$self->{whitespaces}->{reggrp_data}}
    ];

    $self->{global}->{reggrp_data} = [
        {
            regexp      => $CHARSET,
            replacement => sub {
                my $submatches  = $_[0]->{submatches};

				my $compress = $global_compress;

                return $submatches->[0] . " " . $submatches->[1] . ( $compress eq 'pretty' ? "\n" : '' );
            }
        },
        {
            regexp      => $MEDIA,
            replacement => sub {
                my $submatches  = $_[0]->{submatches};
                my $mediatype   = $submatches->[0];
                my $mediarules  = $submatches->[1];

				my $compress = $global_compress;

                $mediatype =~ s/^\s*|\s*$//gs;
                $mediatype =~ s/\s*,\s*/,/gsm;

                $reggrp_mediarules->exec( \$mediarules );

                return '@media ' . $mediatype . '{' . ( $compress eq 'pretty' ? "\n" : '' ) .
                    $mediarules . '}' . ( $compress eq 'pretty' ? "\n" : '' );
            }
        },
        @{$self->{mediarules}->{reggrp_data}}
    ];


    map {
        $self->{ '_reggrp_' . $_ } = Regexp::RegGrp->new(
            {
                reggrp => $self->{$_}->{reggrp_data}
            }
        );
    } @REGGRPS;

    return $self;
}

sub minify {
    my ( $self, $input, $opts );

    unless (
        ref( $_[0] ) and
        ref( $_[0] ) eq __PACKAGE__
    ) {
        $self = __PACKAGE__->init();

        shift( @_ ) unless ( ref( $_[0] ) );

        ( $input, $opts ) = @_;
    }
    else {
        ( $self, $input, $opts ) = @_;
    }

    if ( ref( $input ) ne 'SCALAR' ) {
        carp( 'First argument must be a scalarref!' );
        return undef;
    }

    my $css     = \'';
    my $cont    = 'void';

    if ( defined( wantarray ) ) {
        my $tmp_input = ref( $input ) ? ${$input} : $input;

        $css    = \$tmp_input;
        $cont   = 'scalar';
    }
    else {
        $css = ref( $input ) ? $input : \$input;
    }

    if ( ref( $opts ) eq 'HASH' ) {
        foreach my $field ( @BOOLEAN_ACCESSORS ) {
            $self->$field( $opts->{$field} ) if ( defined( $opts->{$field} ) );
        }

        foreach my $field ( 'compress', 'copyright' ) {
            $self->$field( $opts->{$field} ) if ( defined( $opts->{$field} ) );
        }
    }

	# (re)initialize variables used in the closures
	$reggrp_url = $self->reggrp_url;
	$reggrp_declaration = $self->reggrp_declaration;
	$reggrp_mediarules = $self->reggrp_mediarules;
    $reggrp_content_value = $self->reggrp_content_value;
	$global_compress = $self->compress;

    my $copyright_comment = '';

    if ( ${$css} =~ /$COPYRIGHT_COMMENT/ism ) {
        $copyright_comment = $1;
    }
    # Resets copyright_comment() if there is no copyright comment
    $self->_copyright_comment( $copyright_comment );

    if ( not $self->no_compress_comment() and ${$css} =~ /$PACKER_COMMENT/ ) {
        my $compress = $1;
        if ( $compress eq '_no_compress_' ) {
            return ( $cont eq 'scalar' ) ? ${$css} : undef;
        }

        $self->compress( $compress );
    }

    ${$css} =~ s/$COMMENT/ /gsm;

    $self->reggrp_global()->exec( $css );

    if ( not $self->remove_copyright() ) {
        ${$css} = ( $self->copyright() || $self->_copyright_comment() ) . ${$css};
    }

    return ${$css} if ( $cont eq 'scalar' );
}

1;

__END__

=head1 NAME

CSS::Packer - Another CSS minifier

=for html
<a href='https://travis-ci.org/leejo/css-packer-perl?branch=master'><img src='https://travis-ci.org/leejo/css-packer-perl.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/leejo/css-packer-perl'><img src='https://coveralls.io/repos/leejo/css-packer-perl/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

Version 2.02

=head1 DESCRIPTION

A fast pure Perl CSS minifier.

=head1 SYNOPSIS

    use CSS::Packer;

    my $packer = CSS::Packer->init();

    $packer->minify( $scalarref, $opts );

To return a scalar without changing the input simply use (e.g. example 2):

    my $ret = $packer->minify( $scalarref, $opts );

For backward compatibility it is still possible to call 'minify' as a function:

    CSS::Packer::minify( $scalarref, $opts );

First argument must be a scalarref of CSS-Code.
Second argument must be a hashref of options. Possible options are:

=over 4

=item compress

Defines compression level. Possible values are 'minify' and 'pretty'.
Default value is 'pretty'.

'pretty' converts

    a {
    color:          black
    ;}   div

    { width:100px;
    }

to

    a{
    color:black;
    }
    div{
    width:100px;
    }

'minify' converts the same rules to

    a{color:black;}div{width:100px;}

=item copyright

You can add a copyright notice at the top of the script.

=item remove_copyright

If there is a copyright notice in a comment it will only be removed if this
option is set to a true value. Otherwise the first comment that contains the
word "copyright" will be added at the top of the packed script. A copyright
comment will be overwritten by a copyright notice defined with the copyright
option.

=item no_compress_comment

If not set to a true value it is allowed to set a CSS comment that
prevents the input being packed or defines a compression level.

    /* CSS::Packer _no_compress_ */
    /* CSS::Packer pretty */

=back

=head1 AUTHOR

Merten Falk, C<< <nevesenin at cpan.org> >>. Now maintained by Lee
Johnson (LEEJO)

=head1 BUGS

Please report any bugs or feature requests through
the web interface at L<http://github.com/leejo/css-packer-perl/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc CSS::Packer

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2011 Merten Falk, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CSS::Minifier>,
L<CSS::Minifier::XS>

=cut
