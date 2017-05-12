package Acme::PlayCode::Plugin::ExchangeCondition;

use Moose::Role;
use List::MoreUtils qw/firstidx/;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:FAYLAND';

around 'do_with_token_flag' => sub {
    my $orig = shift;
    my $self = shift;
    my ( $token_flag ) = @_;
    
    my @tokens = $self->tokens;
    my $token  = $tokens[$token_flag];
    
    my $orginal_flag = $token_flag;
    if ( $token->isa('PPI::Token::Operator') ) {
        my $op = $token->content;
        # only 'ne' 'eq' '==' '!=' are exchange-able
        if ( $op eq 'ne' or $op eq 'eq' or $op eq '==' or $op eq '!=' ) {
            # get next tokens
            my (@next_tokens, @next_full_tokens);
            while ( $token_flag++ ) {
                if ($tokens[$token_flag]->isa('PPI::Token::Whitespace') ) {
                    push @next_full_tokens, $tokens[$token_flag];
                    next;
                }
                last if ( $tokens[$token_flag]->isa('PPI::Token::Structure') );
                if ( $tokens[$token_flag]->isa('PPI::Token::Operator') ) {
                    my $op2 = $tokens[$token_flag]->content;
                    if ( $op2 eq 'or' or $op2 eq 'and' or $op2 eq '||' or $op2 eq '&&') {
                        last;
                    }
                }
                last unless ( $tokens[$token_flag] );
                push @next_tokens, $tokens[$token_flag];
                push @next_full_tokens, $tokens[$token_flag];
            }
            $token_flag = $orginal_flag; # roll back
            # get previous tokens
            my (@previous_tokens, @previous_full_tokens);
            while ($token_flag--) {
                if ($tokens[$token_flag]->isa('PPI::Token::Whitespace') ) {
                    unshift @previous_full_tokens, $tokens[$token_flag];
                    next;
                }
                last if ($tokens[$token_flag]->isa('PPI::Token::Structure'));
                if ( $tokens[$token_flag]->isa('PPI::Token::Operator') ) {
                    my $op2 = $tokens[$token_flag]->content;
                    if ( $op2 eq 'or' or $op2 eq 'and' or $op2 eq '||' or $op2 eq '&&') {
                        last;
                    }
                }
                last unless ( $tokens[$token_flag] );
                unshift @previous_tokens, $tokens[$token_flag];
                unshift @previous_full_tokens, $tokens[$token_flag];
            }
            $token_flag = $orginal_flag; # roll back

            # the most simple situation ( $a eq 'a' )
            if (scalar @next_tokens == 1 and scalar @previous_tokens == 1) {
                # exchange-able flag
                my $exchange_able = 0;
                # single and literal are exchange-able
                if ( $next_tokens[0]->isa('PPI::Token::Quote::Single')
                  or $next_tokens[0]->isa('PPI::Token::Quote::Literal') ) {
                    $exchange_able = 1;
                }
                # double without interpolations is exchange-able
                if ( $next_tokens[0]->isa('PPI::Token::Quote::Double') and
                    not $next_tokens[0]->interpolations ) {
                    $exchange_able = 1;
                }
                if ( $exchange_able ) {
                    # remove previous full tokens
                    my $previous_num = scalar @previous_full_tokens;
                    my $next_num     = scalar @next_full_tokens;
                    my @output = @{ $self->output };
                    @output = splice( @output, 0, scalar @output - $previous_num );
                    
                    # exchange starts
                    my @tokens_to_exchange = ( @previous_full_tokens, $token, @next_full_tokens );
                    
                    # find the place of previous_tokens and next_tokens
                    my $prev_place = firstidx { $_ eq $previous_tokens[0] } @tokens_to_exchange;
                    my $next_place = firstidx { $_ eq $next_tokens[0] } @tokens_to_exchange;
                    
                    $tokens_to_exchange[ $prev_place ] = $next_tokens[0];
                    $tokens_to_exchange[ $next_place ] = $previous_tokens[0];

                    foreach my $_token ( @tokens_to_exchange ) {
                        push @output, $self->do_with_token($_token);
                    }

                    # move 'token flag' i forward
                    $token_flag += $next_num + 1;
                    $self->token_flag( $token_flag );
                    $self->output( \@output );
                    return;
                }
            }
        }
    }
    
    $orig->($self, @_);
};

no Moose::Role;

1;
__END__

=head1 NAME

Acme::PlayCode::Plugin::ExchangeCondition - Play code with exchanging condition

=head1 SYNOPSIS

    use Acme::PlayCode;
    
    my $app = new Acme::PlayCode;
    
    $app->load_plugin('ExchangeCondition');
    
    my $played_code = $app->play( $code );
    # or
    my $played_code = $app->play( $filename );
    # or
    $app->play( $filename, { rewrite_file => 1 } ); # override $filename with played code

=head1 DESCRIPTION

    if ( $a eq "a" ) {
        print "1";
    } elsif ( $b eq 'b') {
        print "2";
    } elsif ( $c ne qq~c~) {
        print "3";
    } elsif ( $c eq q~d~) {
        print '4';
    }

becomes

    if ( "a" eq $a ) {
        print "1";
    } elsif ( 'b' eq $b ) {
        print "2";
    } elsif ( $c ne qq~c~) {
        print "3";
    } elsif ( q~d~ eq $c ) {
        print '4';
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
