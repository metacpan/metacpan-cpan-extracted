#!/usr/bin/env perl
$|++;

use Catmandu::Importer::Twitter;
use Catmandu::Exporter::Atom;
use Config::Any::JSON;
use Date::Parse;
use URI::Escape;
use POSIX qw(strftime);
use Getopt::Long;

binmode(STDOUT, ":utf8");

# get twitter keys from config file
my $conf_file = "twitter.json";
my $config    = undef;

GetOptions("c=s" => \$conf_file);

my $query = shift;

unless ($query && -f $conf_file) {
    print STDERR <<EOF;
usage: $0 [-c config] query

where 'config' is a JSON file like:

{
 "twitter_consumer_key": "XXX",
 "twitter_consumer_secret": "XXX",
 "twitter_access_token": "XXX",
 "twitter_access_token_secret": "XXX"
}

The default config file is: $conf_file
EOF
    exit(2);
}

$config = Config::Any::JSON->load($conf_file);

my $in = Catmandu::Importer::Twitter->new(
    query => $query,
    %{$config}
);

my $out = Catmandu::Exporter::Atom->new(
    title => "$query - Twitter search",
    link  => [
        {
            type => 'text/html',
            rel  => 'alternate',
            href =>
              sprintf( 'https://twitter.com/search?q=%s', uri_escape_utf8($query) )
        }
    ]
);

$out->add_many(
    $in->map(
        sub {
            my $obj = $_[0];
            $ret->{id} = $obj->{id};
            $ret->{author}{name} = sprintf "@%s (%s)",
              $obj->{user}->{screen_name}, $obj->{user}->{name};
            $ret->{title} = $obj->{text};
            $ret->{content}{body} = $obj->{text};
            $ret->{content}{body} =~
              s{(@(\w+))}{<a href="https://twitter.com/$2">$1</a>}g;
            $ret->{content}{body} =~
s{(#(\w+))}{sprintf('<a href="https://twitter.com/search?q=%s" title="%s">%s</a>',uri_escape($1),$1,$1)}eg;
            $ret->{link}[0]{href} = sprintf "http://twitter.com/%s/statuses/%s",
              $obj->{from_user}, $obj->{id};
            $ret->{published} = strftime "%Y-%m-%dT%H:%M:%SZ",
              gmtime( str2time( $obj->{created_at} ) );
            $ret->{updated} = $ret->{published};
            $ret;
        }
    )
);

$out->commit;
