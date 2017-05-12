# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
#use Test::UniqueTestNames ;

use Test::Block qw($Plan);

use App::Plog ;
use Directory::Scratch ;
use File::Slurp ;

{
local $Plan = {'run' => 5} ;

my $temporary_directory = Directory::Scratch->new(CLEANUP => 1) ;

my $configuration_directory = $temporary_directory->mkdir('configuration') ;
my $git_repository = $temporary_directory->mkdir('git_repository') ;
my $output_directory = $temporary_directory->mkdir('output_directory') ;

write_file("$git_repository/entry_one.pod", <<'EOF') ;

=head1 Title

=over 2

=item Tags: tag1 tag2

=back

blahh

blahhh

=begin html

<img src="mini_plog.png" align=center >

=end html

=head2 Code

dklfjldjf

 dflmlk
  dsfdf
   dsfdf

=cut
EOF

write_file("$git_repository/entry_two.txt", <<'EOF') ;

Main Header
===========
:Author:    someone

== Level 1
=== Level 2
==== Level 3
===== Level 4


.Optional Title
NOTE: This is an example
      single-paragraph note.
      
Optional Title
[source,perl]
----
# *Source* block
# # Use: highlight code listings
# (require `source-highlight`)
use DBI;
my $dbh = DBI->connect('...',$u,$p)
     or die "connect: $dbh->errstr";
----

[red]#red text# [,yellow]#on yellow#
[,,2]#large# [red,yellow,2]*all bold*
EOF
      
diag `git init $git_repository` ;
diag `cd $git_repository ; git --git-dir=$git_repository/.git add . ` ;
diag `cd $git_repository ; git --git-dir=$git_repository/.git commit -a -m 'initial commit'` ;

# copy t/dot_plog to $configuration_directory
use File::Copy::Recursive 'rcopy' ;
rcopy('t/dot_plog', $configuration_directory) or die "Can't copy the configuration to the teste directory: $!" ;

# modify configuration to point to the temporary directory
my $perl_blog_configuration_file =  "$configuration_directory/perl/config.pl" ;
open my $perl_blog_configuration_fh, '<', $perl_blog_configuration_file or die "Can't open perl blog configuration file: $!" ;
my @perl_blog_configuration = <$perl_blog_configuration_fh> ;
close $perl_blog_configuration_fh ;

open my $new_perl_blog_configuration_fh, '>', $perl_blog_configuration_file or die "Can't open perl blog configuration file for modifications: $!" ;

for (@perl_blog_configuration)
	{
	s{entry_directory => 't/git_repository',}{entry_directory => '$git_repository',} ;
	print $new_perl_blog_configuration_fh $_ ;
	}

close $new_perl_blog_configuration_fh ;

# override global config
write_file ("$configuration_directory/config.pl", "{ plog_root_directory => '$configuration_directory', default_blog => 'perl', }") ;

lives_ok
	{
	App::Plog::create_blog
		(
		# options
		'--configuration_path' => $configuration_directory,
		'--temporary_directory' => $output_directory,
		'--blog_id' => 'perl',

		# commande
		'generate',
		)
	} 'generate blog' ;
	
ok( -e "$output_directory/plog.html", 'blog exists') ;
isnt(-s "$output_directory/plog.html", 0, 'blog has contents') ;

ok( -e "$output_directory/rss.xml", 'rss exists') ;
isnt(-s "$output_directory/rss.html", 0, 'rss has contents') ;
}

