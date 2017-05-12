package Acme::PlayCode::Plugin::DoubleToSingle;

use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:FAYLAND';

around 'do_with_token' => sub {
    my $orig = shift;
    my $self = shift;
    my ( $token ) = @_;

    if ( $token->isa('PPI::Token::Quote::Double') ) {
        # XXX?
        # why treat 
        # bless( {
        #   'separator' => '"',
        #   'content' => '"c\\n"'
        # }, 'PPI::Token::Quote::Double' );
        # "c\\n" as not interpolations
        # bug?
        #
        # why "\012" is not interpolations??
        # another bug?
        
        # skip all '\' because I don't know which is fine
        if ( not $token->interpolations and
             not $token->content =~ /\\/ ) {
            my $str = $token->string;
            if ( $str !~ /\'/) {
                return "'$str'";
            } else {
                if ( $str !~ /\~/ ) {
                    return 'q~' . $str . '~';
                } else {
                    return $token->content;
                }
            }
        }
    } elsif ( $token->isa('PPI::Token::Quote::Interpolate') ) {
        # PPI::Token::Quote::Interpolate no ->interpolations
        my $str = $token->string;
        if ( $str =~ /^\w+$/ ) {
            return "'$str'";
        }
    }
    
    $orig->($self, @_);
};

no Moose::Role;

1;
__END__

=head1 NAME

Acme::PlayCode::Plugin::DoubleToSingle - Play code with Single and Double

=head1 SYNOPSIS

    use Acme::PlayCode;
    
    my $app = new Acme::PlayCode;
    
    $app->load_plugin('DoubleToSingle');
        
    my $played_code = $app->play( $code );
    # or
    my $played_code = $app->play( $filename );
    # or
    $app->play( $filename, { rewrite_file => 1 } ); # override $filename with played code

=head1 DESCRIPTION

    my $a = "a";
    my $b = "'b'";
    my $c = qq~c~;
    my $d = qq~'d'~;
    my $e = q{e};
    my $f = 'f';
    if ( $a eq "a" ) {
        print "ok";
    }

becomes

    my $a = 'a';
    my $b = q~'b'~;
    my $c = 'c';
    my $d = qq~'d'~;
    my $e = q{e};
    my $f = 'f';
    if ( $a eq 'a' ) {
        print 'ok';
    }

=head1 SEE ALSO

L<Acme::PlayCode>, L<Moose>, L<PPI>, L<MooseX::Object::Pluggable>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
