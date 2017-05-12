#!/usr/bin/env perl
use strict;
use warnings;

use Acme::CPANAuthors::Utils;
use Cwd qw(realpath);
use Search::Elasticsearch;
use File::Spec::Functions qw(catfile splitpath updir);

my $VERSION = '0.08';

my $es = Search::Elasticsearch->new(
    nodes            => 'api.metacpan.org',
    cxn_pool         => 'Static::NoPing',
    send_get_body_as => 'POST',
    deflate          => 1,
);

my (%authors, %names);

# TODO: verify the document mapping (data structure) has not changed.

process_authors();
process_releases();
write_file();

exit;


sub process_authors {
    my $req = $es->scroll_helper(
        index       => 'author',
        q           => '*',
        search_type => 'scan',
        scroll      => '5m',
        size        => 1_000,
    );

    while (my $res = $req->next) {
        my $source = $res->{_source};
        my ($pauseid, $name) = @$source{qw(pauseid name)};
        next unless $pauseid;

        $names{$pauseid} = $name || '';

        for my $website (@{$source->{website}}) {
            next unless is_github_site($website);
            $authors{$pauseid} = $name;
            last;
        }

        for my $profile (@{$source->{profile}}) {
            next unless 'github' eq $profile->{name};
            $authors{$pauseid} = $name || '';
            last;
        }
    }
}

sub process_releases {
    my $req = $es->scroll_helper(
        index       => 'release',
        q           => 'status:latest',
        fields      => [qw(author homepage url web)],
        search_type => 'scan',
        scroll      => '5m',
        size        => 1_000,
    );

    while (my $res = $req->next) {
        my $author = delete $res->{fields}{author};
        next if exists $authors{$author};

        for my $url (values %{$res->{fields}}) {
            next unless is_github_site($url);
            $authors{$author} = $names{$author};
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
    my $file = catfile(
        (splitpath(realpath __FILE__))[0, 1], updir,
        qw(lib Acme CPANAuthors GitHub.pm)
    );

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
    for my $cpanid (sort keys %authors) {
        printf $fh "    q(%s) => q(%s),\n", $cpanid, $authors{$cpanid};
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

Copyright (C) 2010-2015 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
