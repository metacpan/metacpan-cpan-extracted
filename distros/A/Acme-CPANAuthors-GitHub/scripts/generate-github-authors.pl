#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Acme::CPANAuthors::Utils;
use Cwd qw(realpath);
use MetaCPAN::Client;
use FindBin;

my $VERSION = '0.09';

my (%name, %github);
process_authors();
process_releases();
write_file();

exit;


sub process_authors {
    my $search = MetaCPAN::Client->new->all('authors');
    AUTHOR:
    while (my $author = $search->next) {
        my $pauseid = $author->pauseid;
        next unless $pauseid;

        my $name = $author->name // '';
        $name{$pauseid} = $name;

        for my $website (@{$author->website // []}) {
            next unless is_github_site($website);
            $github{$pauseid} = $name;
            next AUTHOR;
        }

        for my $profile (@{$author->profile // []}) {
            next unless 'github' eq $profile->{name};
            $github{$pauseid} = $name;
            next AUTHOR;
        }
    }
}


sub process_releases {
    my $search = MetaCPAN::Client->new->release({
        all => [
            { maturity => 'released' },
            { status   => 'latest' },
            {
                either => [
                    { 'resources.repository.url' => '*github.com/*' },
                    { 'resources.repository.web' => '*github.com/*' },
                    { 'resources.homepage'       => '*github.com/*' },
                ]
            },
        ]},
        { _source => [qw(author resources)] }
    );

    while (my $release = $search->next) {
        my $pauseid = $release->author // next;
        next if exists $github{$pauseid};

        my $home = $release->resources->{homepage} // '';
        my $repo = $release->resources->{repository} // {};
        for my $url ($home, @$repo{qw(url web)}) {
            next unless is_github_site($url);
            $github{$pauseid} = $name{$pauseid} // '';
            last;
        }
    }
}


sub is_github_site {
    return $_[0]
        && $_[0] =~ m[
            ^ (?:(?:git | https?)://)? (?:[^.]+\.)? github\.com/
        ]ix;
}


sub write_file {
    my $file = "$FindBin::Bin/../lib/Acme/CPANAuthors/GitHub.pm";

    open my $fh, '>:encoding(utf-8)', $file or die "$file: $!";
    (my $header =<< "    __HEADER__") =~ s/^ +//gm;
        package Acme::CPANAuthors::GitHub;

        use strict;
        use warnings;
        use utf8;

        our \$VERSION = '$VERSION';
        \$VERSION = eval \$VERSION;

        use Acme::CPANAuthors::Register(
    __HEADER__
    print $fh $header;
    for my $pauseid (sort keys %github) {
        printf $fh "    q(%s) => q(%s),\n", $pauseid, $github{$pauseid};
    }
    print $fh <DATA>;
    close $fh;
}


__DATA__
);


1;

__END__

=head1 NAME

Acme::CPANAuthors::GitHub - CPAN Authors with GitHub repositories

=head1 SYNOPSIS

    use Acme::CPANAuthors;

    my $authors  = Acme::CPANAuthors->new('GitHub');

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions('GRAY');
    my $url      = $authors->avatar_url('GRAY');
    my $kwalitee = $authors->kwalitee('GRAY');
    my $name     = $authors->name('GRAY');

=head1 DESCRIPTION

This class provides a hash of PAUSE IDs and names of CPAN authors who have
GitHub repositories.

=head1 SEE ALSO

L<Acme::CPANAuthors>

L<http://github.com/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Acme-CPANAuthors-GitHub>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::CPANAuthors::GitHub

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/acme-cpanauthors-github>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-CPANAuthors-GitHub>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-CPANAuthors-GitHub>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-GitHub>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-CPANAuthors-GitHub/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2017 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
