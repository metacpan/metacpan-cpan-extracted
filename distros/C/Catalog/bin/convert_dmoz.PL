use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w

!GROK!THIS!

print OUT <<'!NO!SUBS!';

use strict;
use vars qw($create $catid_max $record_max %path2catid %catid2path 
	    %stats $verbose $today $exclude);
use Carp;
use POSIX qw(strftime);
use Getopt::Long;
use Catalog::tools::tools;
use Catalog::tools::cgi;

sub main {
    my($what);
    my($load);

    GetOptions("verbose+" => \$verbose,
	       "what=s" => \$what,
	       "load=s" => \$load,
	       "exclude=s" => \$exclude);

    my($input) = @ARGV;

    if(!defined($input) ||
       ! -r $input) {
	print STDERR "
usage: $0 [-v] [-exclude pattern] -what {content|structure} {content.rdf[.gz]|structure.rdf[.gz]}
       $0 [-v] -load all directory
       $0 [-v] -load {category|entry2category|category2category|dmozrecords} file.txt
";
	return;
    }

    $| = 1;

    convert($what, $input) if($what);
    load($load, $input) if($load);

    stats();
}

sub load {
    my($what, $input) = @_;
    my($all) = $what eq 'all';
    my($dir) = $input;

    $input = "$dir/category.txt" if($all);
    if($all || $what eq 'category') {
	system("mysql -e \"delete from catalog_category_dmoz where rowid > 1;\" dmoz");
	system("mysql -e \"load data infile '$input' into table catalog_category_dmoz;\" dmoz");
	system("echo catalog_category_dmoz; mysql -e \"select count(*) from catalog_category_dmoz;\" dmoz");
    } 

    $input = "$dir/entry2category.txt" if($all);
    if($all || $what eq 'entry2category') {
	system("mysql -e \"delete from catalog_entry2category_dmoz;\" dmoz");
	system("mysql -e \"load data infile '$input' into table catalog_entry2category_dmoz;\" dmoz");
	system("echo catalog_entry2category_dmoz; mysql -e \"select count(*) from catalog_entry2category_dmoz;\" dmoz");
    }

    $input = "$dir/category2category.txt" if($all);
    if($all || $what eq 'category2category') {
	system("mysql -e \"delete from catalog_category2category_dmoz;\" dmoz");
	system("mysql -e \"load data infile '$input' into table catalog_category2category_dmoz;\" dmoz");
	system("echo catalog_category2category_dmoz; mysql -e \"select count(*) from catalog_category2category_dmoz;\" dmoz");
    }

    $input = "$dir/dmozrecords.txt" if($all);    
    if($all || $what eq 'dmozrecords') {
	system("mysql -e \"delete from dmozrecords;\" dmoz");
	system("mysql -e \"load data infile '$input' into table dmozrecords;\" dmoz");
	system("echo dmozrecords; mysql -e \"select count(*) from dmozrecords;\" dmoz");
    }

    system("mysql -e \"drop table if exists catalog_path_dmoz\" dmoz");
}

sub convert {
    my($what, $input) = @_;

    $today = strftime("%Y/%m/%d", localtime());

    my($count) = 0;
    my($threshold) = 10000;
    if($what eq 'content') {
	$input = "gzip -dc '$input' |" if $input =~ /\.gz/;
	open(FROM, "$input") or error("cannot open $input for reading : $!");
	open(CATEGORY, ">category.txt") or error("cannot open category.txt for writing : $!");
	open(ENTRY2CATEGORY, ">entry2category.txt") or error("cannot open entry2category.txt for writing : $!");
	open(CATEGORY2CATEGORY, ">category2category.txt") or error("cannot open category2category.txt for writing : $!");
	open(DMOZRECORDS, ">dmozrecords.txt") or error("cannot open dmozrecord.txt for writing : $!");
	my @buffer;
	my($accumulate);
	while(<FROM>) {
	    if(/^<Topic/) {
		if($accumulate) {
		    handle_content(join("", @buffer));
		    @buffer = ();
		}
		$accumulate = 1;
	    }
	    push(@buffer, $_) if $accumulate;
	    print "." if(++$count % $threshold == 0);
	}

	handle_content(join("", @buffer));
	close(CATEGORY);
	close(ENTRY2CATEGORY);
	close(CATEGORY2CATEGORY);
	close(DMOZRECORDS);
	close(FROM);
    }
}

sub fixup {
    my($string, $default) = @_;

    return $default if(!$string || $string =~ /^\s*$/s);

    $string =~ s/[\000-\037\177]//gs;
    $string =~ s/&amp;/&/gs;
    $string =~ s/&lt;/</gs;
    $string =~ s/&gt;/>/gs;
    $string =~ s/&quot;/\"/gs;
    $string = Catalog::tools::cgi::myescapeHTML($string);

    return $string;
}

sub loadquote {
    my($string) = @_;
    $string =~ y/\n\t/  /;
    return $string;
}

sub stats {
    print "\nStatistics: \n" if(keys(%stats));
    my($label, $value);
    while(($label, $value) = each(%stats)) {
	print "$label = $value\n";
    }
}

sub isprint {
    my($string) = @_;
    return !($string =~ /[\000-\037\177-\377]/);
}

$catid_max = 10000000;
$record_max = 1;

#
# Parse a chunk going from a <Topic> tag to another.
#
sub handle_content {
    my($buffer) = @_;

    my($path, $catid);
    ($path) = $buffer =~ m|<Topic r:id=\"Top(.*?)\">|;

    if(!isprint($path)) {
	warn("ignore category with non printable characters $path") if($verbose);
	$stats{'Non ascii printable category'}++;
	return;
    }
    $path =~ s/_/ /g;
    $path =~ s/\s+$//;

    if($exclude && $path =~ /$exclude/s) {
	warn("exclude category $path") if($verbose);
	$stats{'Excluded Category'}++;
	return;
    }
    
    my($definition) = 0;
    ($catid) = $buffer =~ m|<catid>(\d+)</catid>|s;
    if(exists($path2catid{$path})) {
	if($path2catid{$path} ne $catid) {
	    warn("catid redefined for $path ($path2catid{$path} -> $catid) ignore") if($verbose);
	    $catid = $path2catid{$path};
	}
	warn("multiple instances of $path") if($verbose);
	$definition = 1;
    }
    if(defined($catid) && exists($catid2path{$catid})) {
	warn("catid for $path already used by $catid2path{$catid}, ignore") if($verbose);
	$stats{'Category id clash'}++;
	$catid = undef;
    }
    if(!defined($catid)) {
	$catid = $catid_max++;
	$stats{'Category id generated'}++;
	warn("missing <catid> for $path, generate $catid") if($verbose);
    }
    $path2catid{$path} = $catid;
    $catid2path{$catid} = $path;

    #
    # No category definition so far, add one.
    #
    if(!$definition) {
	my($parent, $name) = $path =~ m|(.*)/(.*)|;
	#
	# Ignore root
	#
	if(!defined($name) || $name =~ m/^\s*$/) {
	    $stats{'root'}++;
	    warn("more than one root : $path") if($stats{'root'} > 1 && $verbose);
	    return;
	}
	$name = fixup($name, 'No name');
	my($parent_id) = find_parent_id($parent);

	print CATEGORY "$catid\t$today\t$today\t0\t" . loadquote($name) . "\t0\t\n";
	print CATEGORY2CATEGORY "0\t$today\t$today\t0\t$parent_id\t$catid\t\n";
    }

    my(@records);
    while($buffer =~ m|<ExternalPage (.*?)</ExternalPage>|sg) {
	my($record) = $1;
	my($url, $title, $description);
	($url) = $record =~ m|about=\"(.*?)\"|s;
	($title) = $record =~ m|<d:Title>(.*)</d:Title>|s;
	($description) = $record =~ m|<d:Description>(.*)</d:Description>|s;

	push(@records, {
	    'rowid' => $record_max,
	    'url' => loadquote(fixup($url, 'Nourl')),
	    'title' => loadquote(fixup($title, 'No title')),
	    'description' => loadquote(fixup($description, 'No description')),
	});
	$record_max++;
	$stats{'Record loaded'}++;
    }

    my($record);
    foreach $record (@records) {
	print ENTRY2CATEGORY "$today\t$today\t0\t$record->{'rowid'}\t$catid\n";
    }

    foreach $record (@records) {
	print DMOZRECORDS "0\t$today\t$today\t\t$record->{'url'}\t$record->{'title'}\t$record->{'description'}\n";
    }

    $stats{'Category loaded'}++;
}

sub find_parent_id {
    my($path) = @_;

    if(exists($path2catid{$path})) {
	return $path2catid{$path};
    } else {
	my($parent, $name) = $path =~ m|(.*)/(.*)|;
	my($parent_id) = find_parent_id($parent);
	my($path_id) = $catid_max++;
	$path2catid{$path} = $path_id;
	$catid2path{$path_id} = $path;
	warn("$path automatically generated") if($verbose);
	$stats{'Generated category'}++;
	print CATEGORY "$path_id\t$today\t$today\t0\t" . loadquote($name) . "\t0\t\n";
        return $path_id;    
    }
}

main();

!NO!SUBS!

# Local Variables: ***
# mode: perl ***
# End: ***
