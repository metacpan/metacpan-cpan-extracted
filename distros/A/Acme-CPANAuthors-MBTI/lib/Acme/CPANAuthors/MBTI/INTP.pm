use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Acme::CPANAuthors::MBTI::INTP;

# ABSTRACT: The TiNe CPAN Authors

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

our $VERSION = '0.001002';
#<<<
# Code inserted by inc/expand_author_list#authors_to_code
# by Dist::Zilla::Plugin::MungeFile::WithDataSection 0.009
## no critic (ValuesAndExpressions::RestrictLongStrings)
my %authors  = (
    KENTNL => 'Kent Fredric',
);

my %avatar_urls = (
    KENTNL => 'https://secure.gravatar.com/avatar/4b96677ae9ecbe76b8c33ead244f7407?s=80&d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F4b96677ae9ecbe76b8c33ead244f7407%3Fs%3D130%26d%3Didenticon',
);

## use critic








sub authors { return ( wantarray ? %authors : \%authors ) }







sub category { return 'MBTI::INTP' }







sub avatar_url {
  my ( $id ) = @_;
  return $avatar_urls{$id};
}

# end generated code

#>>>

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::MBTI::INTP - The TiNe CPAN Authors

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

    use Acme::CPANAuthors;
    use Acme::CPANAuthors::MBTI::INTP;
    # Or just use Acme::CPANAuthors::MBTI

    my $authors  = Acme::CPANAuthors->new('MBTI::INTP');
    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions('KENTNL');
    my $url      = $authors->avatar_url('KENTNL');
    my $kwalitee = $authors->kwalitee('KENTNL');

    my %authorshash    = Acme::CPANAuthors::MBTI::INTP->authors;
    my $authorshashref = Acme::CPANAuthors::MBTI::INTP->authors;
    my $category       = Acme::CPANAuthors::MBTI::INTP->category;

=head1 DESCRIPTION

This class provides a hash of PAUSE ID's and names of authors
who have identified themselves as   L<< C<INTP>|https://en.wikipedia.org/wiki/INTP >>

=head1 METHODS

=head2 authors

  my $scalar_ref = Acme::CPANAuthors::MBTI::INTP->authors;
  my %hash       = Acme::CPANAuthors::MBTI::INTP->authors;

=head2 category

  my $scalar = Acme::CPANAuthors::MBTI::INTP->category;

=head2 avatar_url

  my $url = Acme::CPANAuthors::MBTI::INTP->avatar_url('KENTNL');

=for html <div style="text-align:center;padding:0px!important;overflow-y:hidden;
margin-left: auto; margin-right: auto; max-width: 430px">
<!-- Data inserted by inc/expand_author_list#authors_to_avatars
 by Dist::Zilla::Plugin::MungeFile::WithDataSection 0.009 -->
<a href="http://metacpan.org/author/KENTNL"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/4b96677ae9ecbe76b8c33ead244f7407?s=80&d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F4b96677ae9ecbe76b8c33ead244f7407%3Fs%3D130%26d%3Didenticon" alt="KENTNL" title="KENTNL (Kent Fredric), 178 distributions" /></span></a>
</div>

For more details see L<< C<Acme::CPANAuthors::MBTI>|Acme::CPANAuthors::MBTI >>.

=over 4

=item * L<< C<INTP> on personalitypage.com|http://personalitypage.com/INTP.html >>

=item * L<< C<INTP> on typelogic.com|http://typelogic.com/intp.html >>

=item * L<< C<INTP> on Wikipedia|https://en.wikipedia.org/wiki/INTP >>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
