#!/usr/bin/perl

use warnings;
use Data::Dumper;
use Term::Prompt;
use LWP::UserAgent;
use URI::Find;
use Bookmarks::Parser;
use Getopt::Long;

$|++;
my $skipknown;

GetOptions("skipknown" => \$skipknown);

my $ua = LWP::UserAgent->new();
my $bookmarksfile = '/home/castaway/.opera8.0/opera6.adr';
$bookmarksfile = prompt('x', 'Bookmarks file to add to:', '', $bookmarksfile);
die "$!" unless(-e $bookmarksfile);
print "Using $bookmarksfile.\n";
$bookmarksfilenew = prompt('x', 'Bookmarks file to save as:', '', "${bookmarksfile}.new");
## url bookmarks?

my $bookmarks = Bookmarks::Parser->new();
$bookmarks->parse({filename => $bookmarksfile});
die "Can't parse $bookmarksfile\n" unless($bookmarks);

my $srcfile = '/home/castaway/stuff';
$srcfile = prompt('x', 'Import from file:', '', $srcfile);
die "$!" unless(-e $srcfile);
print "Importing from $srcfile ...\n";

my $srcfh;
my $storeduris = 0;
my $doneimporting = 0;
my $parseuri = URI::Find->new(\&adduri);
open($srcfh, "<$srcfile") or die "Can't open $srcfile ($!)";
while(my $srcdata =  <$srcfh>)
{
    $storeduris += $parseuri->find(\$srcdata);
    last if($doneimporting);
}
close($srcfh);
print "Imported $storeduris URLs\n";

# print Dumper($bookmarks);

if(!-e "${bookmarksfilenew}")
{
    $bookmarks->write_file({filename => "${bookmarksfilenew}"});
}

sub adduri
{
    my ($uri, $uristr) = @_;

    my @find = $bookmarks->find_items({url => $uristr});
    return $uristr if(@find && $skipknown);

    if(@find)
    {
#    print Dumper(\@find);
        print "Found $uristr already at:\n";
        foreach my $item (@find)
        {
            print "  ", $bookmarks->get_path_of($item), "\n";
        }
    }
    my $title;
    my $get_title_ref = sub {
        my ($data, $response, $protocol) = @_;
        ($title) = $data =~ m{<title>(.+?)</title>}i;
        die if($title);
    };
    $ua->get($uristr, ':content_cb' => $get_title_ref,
             ':read_size_hint' => 1024);
    $title ||= '';
    print "Page title is $title\n";

    return $uristr if(!prompt('y', "Add $uristr?", '', 'n'));
    my $urititle = prompt('x', 'Enter title for this URI:', '', $title);
    die "No title!" if(!$urititle);

    my $addhere = 0;
    my @folders = ({name => 'root', type => 'folder'});
    my $path = '';
    my $action = '';
    my $f;
    until($action =~ /a/i) 
    {
        my @names = ('..', map {$_->{type} eq 'folder' ? $_->{name}: () } @folders);
        $addhere = prompt('m', { prompt => 'Pick a folder:',
                                 title  => "Folders ($path)",
                                 items  => \@names,
                                 cols   => 1,
                             }, '', '1');
        if($addhere == 0)
        {
            @folders = $f->{parent} ? $bookmarks->get_folder_contents($bookmarks->get_from_id($f->{parent})) :
                $bookmarks->get_top_level();
            $path =~ s{([^/]+)/$}{};
            next;
        }
        ($f) = grep {$_->{name} eq $names[$addhere]} @folders;
#        print Dumper($f);
## Add new folder?
        print "Current folder: ", $bookmarks->get_path_of($f), $f->{name}, "\n";
        $action = prompt('x', '(s)subfolder, (a)dd here, (d)done, (c)ancel (q)uit:', '', 's'); 
        if($action eq 's')
        {
            @folders = defined $f->{id} ? $bookmarks->get_folder_contents($f) :
                $bookmarks->get_top_level();
            $path .= $f->{name} . '/';
        }
        elsif($action eq 'd')
        {
            # done adding, save what we have ?
            $doneimporting = 1;
            return $uristr;
        }
        elsif($action eq 'c')
        {
            # decided not to add this uri after all
            print "Not adding $uristr, ok\n";
            return $uristr;
        }
        elsif($action eq 'q')
        {
            die "Quitting without saving changes\n";
        }
#        print Dumper($f);
#        print Dumper(\@folders);

    }

    print "Adding $uristr to ", $f->{name}, ".\n";
    my $newbm = { name => $urititle,
                  url  => $uristr,
                  created => time(),
                  type  => 'url',
              };
    my $bm = $bookmarks->add_bookmark($newbm, $f);
    print Dumper($bm);

    return $uristr;
}




