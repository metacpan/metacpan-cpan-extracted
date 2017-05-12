package Acme::PlayCode::Plugin::NumberPlus;

use Moose::Role;
use List::MoreUtils qw/insert_after/;
use PPI::Token::Comment;

our $VERSION   = '0.11';
our $AUTHORITY = 'cpan:FAYLAND';

around 'do_with_token_flag' => sub {
    my $orig = shift;
    my $self = shift;
    my ( $token_flag ) = @_;
    
    my @tokens = $self->tokens;
    my $token  = $tokens[$token_flag];
    
    use Data::Dumper;
#    print STDERR Dumper(\$token);
    
    my $orginal_flag = $token_flag;
    if ( $token->isa('PPI::Token::Operator') ) {
        my $op = $token->content;
        # only '+' '-' '*' '/' are do-able
        if ( $op eq '+' or $op eq '-' or $op eq '*' or $op eq '/' ) {
            # get next tokens
            my (@next_full_tokens);
            while ( $token_flag++ ) {
                if ($tokens[$token_flag]->isa('PPI::Token::Whitespace') ) {
                    push @next_full_tokens, $tokens[$token_flag];
                    next;
                }
                last if ( $tokens[$token_flag]->isa('PPI::Token::Structure') );
                if ( $tokens[$token_flag]->isa('PPI::Token::Operator') ) {
                    my $op2 = $tokens[$token_flag]->content;
                    unless ( $op2 eq '+' or $op2 eq '-' or $op2 eq '*' or $op2 eq '/' ) {
                        last;
                    }
                }
                last unless ( $tokens[$token_flag] );
                push @next_full_tokens, $tokens[$token_flag];
            }
            # remove last space
            pop @next_full_tokens if ( $next_full_tokens[-1]->isa('PPI::Token::Whitespace'));
            $token_flag = $orginal_flag; # roll back
            # get prev tokens
            my (@prev_full_tokens);
            while ($token_flag--) {
                if ($tokens[$token_flag]->isa('PPI::Token::Whitespace') ) {
                    unshift @prev_full_tokens, $tokens[$token_flag];
                    next;
                }
                last if ($tokens[$token_flag]->isa('PPI::Token::Structure'));
                if ( $tokens[$token_flag]->isa('PPI::Token::Operator') ) {
                    my $op2 = $tokens[$token_flag]->content;
                    unless ( $op2 eq '+' or $op2 eq '-' or $op2 eq '*' or $op2 eq '/' ) {
                        last;
                    }
                }
                last unless ( $tokens[$token_flag] );
                unshift @prev_full_tokens, $tokens[$token_flag];
            }
            $token_flag = $orginal_flag; # roll back
            # remove first space
            shift @prev_full_tokens if ( $prev_full_tokens[0]->isa('PPI::Token::Whitespace'));

            # only do-able for number, space, operator
            my $do_able = 1;
            $do_able = 0 unless (scalar @prev_full_tokens and scalar @next_full_tokens);
            if ( $do_able ) {
				foreach ( @prev_full_tokens, @next_full_tokens ) {
					unless ( $_->isa('PPI::Token::Whitespace') or $_->isa('PPI::Token::Number') or
						( $_->isa('PPI::Token::Operator') and $_->content =~ /^[\+\-\*\/]$/ ) ) {
							$do_able = 0;
							last;
					}
				}
			}
            if ( $do_able ) {
                # remove prev full tokens
                my $prev_num = scalar @prev_full_tokens;
                my $next_num = scalar @next_full_tokens;
                my @output = @{ $self->output };
                @output = splice( @output, 0, scalar @output - $prev_num );
                                
                my $str = join('', @prev_full_tokens, $token, @next_full_tokens);
                $str = eval($str);
                push @output, $str;
                my $comment = " # $str = ";
                foreach ( @prev_full_tokens, $token, @next_full_tokens ) {
                    $comment .= $_->content;
                }

                # move 'token flag' i forward
                $token_flag += $next_num + 1;
                my $to_be_set = $token_flag;
                
                # add comment like ' # 3 = 1 + 2'
                while ( $token_flag ) {
                    my $_token = $tokens[$token_flag];
                    unless ( $_token ) {
                        push @tokens, new PPI::Token::Comment($comment);
                        last;
                    }
                    push @output, $orig->($self, $token_flag);
                    $token_flag++;
                    if ( $_token->isa('PPI::Token::Structure') and
                         $_token->content ne ')' ) {
                        insert_after { $_ eq $_token } new PPI::Token::Comment($comment) => @tokens;
                        last;
                    }
                }

                $self->token_flag( $token_flag );
                $self->output( \@output );
                $self->tokens( \@tokens );
                return;
            }
        }
    }
    
    $orig->($self, @_);
};

no Moose::Role;

1;
__END__

=head1 NAME

Acme::PlayCode::Plugin::NumberPlus - Play code with plus number

=head1 SYNOPSIS

    use Acme::PlayCode;
    
    my $app = new Acme::PlayCode;
    
    $app->load_plugin('NumberPlus');
    
    my $played_code = $app->play( $code );
    # or
    my $played_code = $app->play( $filename );
    # or
    $app->play( $filename, { rewrite_file => 1 } ); # override $filename with played code

=head1 DESCRIPTION

    my $a = 1 + 2;

becomes

    my $a = 3; # 1 + 2

=head1 SEE ALSO

L<Acme::PlayCode>, L<Moose>, L<PPI>, L<MooseX::Object::Pluggable>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
