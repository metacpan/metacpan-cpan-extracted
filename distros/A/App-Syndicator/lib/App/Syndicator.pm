package App::Syndicator;
BEGIN {
  $App::Syndicator::VERSION = '0.0061';
}
# Dist::Zilla: +PodWeaver

use MooseX::Declare;

class App::Syndicator with (App::Syndicator::Config, 
    MooseX::Getopt::Dashes) {
    use App::Syndicator::Types qw/File WritableFile UriArray/;
    use App::Syndicator::UI;
    use App::Syndicator::DB;

    our $BASE = "$ENV{HOME}/.syndicator";

    has +configfile => (
        is => 'ro',
        isa => File,
        required => 1,
        default => "$BASE/config.json"
    );

    has sources => (
        is => 'rw',
        isa => UriArray,
        coerce => 1,
        required => 1,
        traits => ['NoGetopt']
    );

    has dbfile => (
        is => 'ro',
        isa => WritableFile,
        required => 1,
        default => "$BASE/main.db"
    );

    method run {
        my $db = App::Syndicator::DB->new(
            dsn => "DBI:SQLite:dbname=".$self->dbfile,
            sources => $self->sources,
        );

        my $ui = App::Syndicator::UI->new(
            db => $db,
        );

        $ui->mainloop;
    }
}

1;


=pod

=head1 NAME

App::Syndicator

=head1 VERSION

version 0.0061

=head1 NAME

App::Syndicator - Curses interface for reading feeds.

=head1 USAGE

 # first run
 $ syndicator --init

 # add your own feeds
 $ vim ~/.syndicator/config.json 

 # run
 $ syndicator 2> errors.log

 $ syndicator --config=config.any --db=sqlite.db

=head2 EXAMPLE CONFIG

 {
    "sources": [
            "http://blogs.perl.org/atom.xml",
            "http://www.perl.org/pub/atom.xml",
            "http://planet.perl.org/rss20.xml",
            "http://ironman.enlightenedperl.org/atom.xml",
            "http://rss.slashdot.org/Slashdot/slashdot",
            "http://www.theregister.co.uk/software/headlines.atom"
    ]
}

=head1 SEE ALSO

L<XML::Feed::Aggregator>

=head1 AUTHOR

Robin Edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robin Edwards.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

