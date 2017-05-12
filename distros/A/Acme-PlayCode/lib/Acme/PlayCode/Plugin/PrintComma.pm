package Acme::PlayCode::Plugin::PrintComma;

use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:FAYLAND';

use vars qw/$printcomma_start/;

around 'do_with_token' => sub {
    my $orig = shift;
    my $self = shift;
    my ( $token ) = @_;

    my $token_flag = $self->token_flag;
    my @tokens = $self->tokens;

    $printcomma_start = 0 unless ( defined $printcomma_start );

    if ( $token->isa('PPI::Token::Word') and $token->content eq 'print' ) {
        $printcomma_start = 1;
    } elsif ( $token->isa('PPI::Token::Structure') ) {
        $printcomma_start = 0;
    } elsif ( $printcomma_start and $token->isa('PPI::Token::Operator')
        and $token->content eq '.' ) {
        if ( $tokens[$token_flag - 1]->isa('PPI::Token::Whitespace') ) {
            $self->output->[-1] = 'Acme::PlayCode::!@#$%^&*()_+';
        }
        return ',';
    }
    
    $orig->($self, @_);
};

no Moose::Role;

1;
__END__

=head1 NAME

Acme::PlayCode::Plugin::PrintComma - Play code with printing comma

=head1 SYNOPSIS

    use Acme::PlayCode;
    
    my $app = new Acme::PlayCode;
    
    $app->load_plugin('PrintComma');
        
    my $played_code = $app->play( $code );
    # or
    my $played_code = $app->play( $filename );
    # or
    $app->play( $filename, { rewrite_file => 1 } ); # override $filename with played code

=head1 DESCRIPTION

    print "a " . "print 'a' . 'b'" . "c\n";

becomes

    print "a ", "print 'a' . 'b'", "c\n";

=head1 SEE ALSO

L<Acme::PlayCode>, L<Moose>, L<PPI>, L<MooseX::Object::Pluggable>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
