package Acme::PlayCode;

use Moose;
use PPI;
use Path::Class ();

our $VERSION   = '0.12';
our $AUTHORITY = 'cpan:FAYLAND';

with 'MooseX::Object::Pluggable';

has 'tokens' => (
    is  => 'rw',
    isa => 'ArrayRef',
    auto_deref => 1,
    default    => sub { [] },
);
has 'token_flag' => ( is => 'rw', isa => 'Num', default => 0 );

has 'output' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] }
);

sub play {
    my ( $self, $code, $opts ) = @_;
    
    my $file;
    if ( $code !~ /\s/ and -e $code ) {
        $file = Path::Class::File->new($code);
        $code = $file->slurp();
    }
    
    # clear to multi-run
    $self->output( [] );
    $self->token_flag( 0 );
    
    my $doc    = PPI::Document->new( \$code );
    $self->tokens( $doc->find('PPI::Token') );

    $self->do_with_tokens();
    
    my @output = @{ $self->output };
    # check Acme::PlayCode::Plugin::PrintComma
    @output = grep { $_ ne 'Acme::PlayCode::!@#$%^&*()_+' } @output;
    my $output = join('', @output);
    if ( $opts->{rewrite_file} and $file ) {
        my $fh = $file->openw();
        print $fh $output;
        $fh->close();
        
    }
    return $output;
}

sub do_with_tokens {
    my ( $self ) = @_;
    
    while ( $self->token_flag < scalar @{$self->tokens}) {
        my $orginal_flag = $self->token_flag;
        my $content = $self->do_with_token_flag( $self->token_flag );
        push @{ $self->output }, $content if ( defined $content );
        # if we don't move token_flag, ++
        if ( $self->token_flag == $orginal_flag ) {
            $self->token_flag( $self->token_flag + 1 );
        }
    }
}

sub do_with_token_flag {
    my ( $self, $token_flag ) = @_;
    
    my @tokens = $self->tokens;
    my $token = $tokens[$token_flag];
    
    return $self->do_with_token( $token );
}

sub do_with_token {
    my ( $self, $token ) = @_;

    my $token_flag = $self->token_flag;
    my @tokens = $self->tokens;
    if ( $token->isa('PPI::Token::HereDoc') ) {
        my @output = @{ $self->output };
        
        my @next_tokens;
        my $old_flag = $token_flag;
        while ( $old_flag++ ) {
            push @next_tokens, $tokens[$old_flag];
            last if ( $tokens[$old_flag]->content eq ';' );
        }
        push @output, $token->content,
            join('', map { $_->content } @next_tokens ), "\n",
            join('', $token->heredoc),
            $token->terminator;
        
        # skip next itself and next ';'
        $self->token_flag( $token_flag + 1 + scalar @next_tokens );
        $self->output( \@output );
        return;
    } else {
        return $token->content;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Acme::PlayCode - Code transforming to avoid typical typing mistakes

=head1 SYNOPSIS

    use Acme::PlayCode;
    
    my $app = new Acme::PlayCode;
    
    $app->load_plugin('DoubleToSingle');
    $app->load_plugin('ExchangeCondition');
    
    my $played_code = $app->play( $code );
    # or
    my $played_code = $app->play( $filename );
    # or
    $app->play( $filename, { rewrite_file => 1 } ); # override $filename with played code

=head1 ALPHA WARNING

L<Acme::PlayCode> is still in its infancy. No fundamental changes are expected, but
nevertheless backwards compatibility is not yet guaranteed.

=head1 DESCRIPTION

It aims to change the code to be better (to be worse if you want).

More description and API detais will come later.

=head1 PLUGINS

=over 4

=item L<Acme::PlayCode::Plugin::Averything>

load all plugins we found.

=item L<Acme::PlayCode::Plugin::DoubleToSingle>

Play code with Single and Double

=item L<Acme::PlayCode::Plugin::ExchangeCondition>

Play code with exchanging condition

=item L<Acme::PlayCode::Plugin::PrintComma>

Play code with printing comma

=item L<Acme::PlayCode::Plugin::NumberPlus>

Play code with plus number

=back

=head1 SEE ALSO

L<Moose>, L<PPI>, L<MooseX::Object::Pluggable>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

The L<Moose> Team.

Jens Rehsack, for the description (RT 53680)

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
