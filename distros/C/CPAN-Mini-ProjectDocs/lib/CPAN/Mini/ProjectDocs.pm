
package CPAN::Mini::ProjectDocs ;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(generate_html get_module_distribution generate_cache search_modules) ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.03';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use CPAN::PackageDetails ;
use Digest::MD5;
use File::Slurp ;
use Data::Dumper ;
use Archive::Tar ;
use Pod::ProjectDocs;

#-------------------------------------------------------------------------------

=head1 NAME

CPAN::Mini::ProjectDocs - mini CPAN documentation browser

=head1 SYNOPSIS

see the B<mcd> command for a full example.

=head1 DESCRIPTION

This module and associated script B<mcd> let you search and display documentation for the modules in you CPAN mini.
The documentation is displayed in your browser (text mode browsers supported)

=head1 DOCUMENTATION

You most probably want to run the B<mcd> script, use the I<--help> option for help.

=head1 SUBROUTINES/METHODS

=cut

#-------------------------------------------------------------------------------

sub get_mcd_paths
{

=head2 get_mcd_paths($cpan_mini, $mcd_cache)

Given a CPAN mini location and a cache location, computes a list containing the paths used by CPAN::Mini::ProjectDocs.

I<Arguments>

=over 2 

=item $cpan_mini - Location of the CPAN::MINI repository

=item $mcd_cache - Location of the cache maintained by CPAN::Mini::ProjectDocs

=back

I<Returns> - A list containing the paths used by CPAN::Mini::ProjectDocs

I<Exceptions> - None

=cut

my ($cpan_mini, $mcd_cache) = @_ ;

my $modules_details_file = "$cpan_mini/modules/02packages.details.txt.gz" ;
my $modules_details_txt_md5_file = "$mcd_cache/packages.details.md5.txt" ;
my $modules_details_cache_file = "$mcd_cache/packages.details.cache" ;
my $modules_details_cache_all_names = "${modules_details_cache_file}_all_names.txt" ;

return
	(
	$modules_details_file,
	$modules_details_txt_md5_file,
	$modules_details_cache_file,
	$modules_details_cache_all_names
	) ;
} 

#---------------------------------------------------------------------------------------------------------

sub generate_html
{

=head2 generate_html($cpan_mini, $mcd_cache, $distribution, $html_index)

Generates the HTML documentation for $distribution. The generation is performed only if the
documentation does not exist in the cache.

I<Arguments>

=over 2 

=item $cpan_mini - Location of the CPAN::MINI repository

=item $mcd_cache - Location of the cache maintained by CPAN::Mini::ProjectDocs

=item $distribution - Location of the distribution containing the module to display

=item $html_index - Boolean - generate a pure HTML index for text based browser

=back

I<Returns> - $html_documentation_location

I<Exceptions> - problems with the distribution extraction, write errors on the file system, ...

=cut

my ($cpan_mini, $mcd_cache, $distribution, $html_index) = @_ ;

my ($module_directory) = $distribution =~ /([^\/]+)\.tar.gz$/ ;
my $html_directory = "$mcd_cache/generated_html/$module_directory" ;
my $html_directory_md5 = "$html_directory/md5.txt" ;

my $regenerate_html = 0 ;

my ($modules_details_file) = get_mcd_paths($cpan_mini, $mcd_cache) ;
my $modules_details_txt_md5 = get_file_MD5($modules_details_file) ;

#check if the html was already generated
if(-e $html_directory)
	{
	eval
		{
		my  $mcd_cache_md5 = read_file($html_directory_md5) ;
		$regenerate_html++ if $mcd_cache_md5 ne $modules_details_txt_md5 ;
		} ;
		
	$regenerate_html++ if  $@ ; # file not found
	}
else
	{
	$regenerate_html++ ;
	}
	
if($regenerate_html)
	{
	my $tar = Archive::Tar->new($distribution) ;
	$tar->setcwd($mcd_cache);
	$tar->extract() ;
	
	mkdir "$mcd_cache/generated_html/" ;
	mkdir $html_directory ;
	
	Pod::ProjectDocs->new
		(
		outroot => $html_directory,
		libroot => -e "$mcd_cache/$module_directory/lib" ? "$mcd_cache/$module_directory/lib" : "$mcd_cache/$module_directory",
		title   => $distribution,
		)->gen() ;
	
	write_file($html_directory_md5, $modules_details_txt_md5) ;
	}
	
my $html_documentation_location = "$mcd_cache/generated_html/$module_directory/index.html" ;

if($html_index)
	{
	$html_documentation_location = generate_pure_html_index("$mcd_cache/generated_html/$module_directory/", 'index.html') ;
	}

return $html_documentation_location;
}

#---------------------------------------------------------------------------------------------------------

sub generate_pure_html_index
{

=head2 generate_pure_html_index($path, $file)

Generate a pure HTML index for text based browsers.

I<Arguments>

=over 2 

=item $path - path to the POD::ProjDocs generated index file

=item $file - POD::ProjDocs generated  index file

=back

I<Returns> - The location of the pure HTML index

I<Exceptions> - None

=cut

my ($path, $file) = @_ ;

my $index = read_file("$path/$file") ;

# convert JS data structure to Perl data structure
my ($data) = $index =~ m/var managers = (.*?)function render\(pattern\)/sm ;

my $perl_data_structure = '' ;
my $in_string = 0 ;

for my $character (split //, $data)
	{
	if($in_string)
		{
		$perl_data_structure .= $character ;
		$in_string = 0 if $character eq q{"} ;
		}
	else
		{
		$in_string = 1 if $character eq q{"} ;
		
		if($character eq q{:})
			{
			$perl_data_structure .= q{=>} ;
			}
		else
			{
			$perl_data_structure .= $character ;
			}
		}
	}
	
$data = eval  $perl_data_structure ;

my $html = '' ;

for my $section (@{$data})
	{
	$html .= <<EOH ;
<div class="box">
<h2 class="t2">$section->{desc}</h2>
	<table width='100%'>
EOH

	my $row_class = 'r' ;

	for my $module (@{$section->{records}})
		{
		$html .= <<EOR ;
		<tr class=$row_class>
			<td nowrap='nowrap'>
				<a href= $module->{path}>
				&nbsp; $module->{name}
				</a>
			</td>
			<td width='99%'>
				<small>
				&nbsp; $module->{title}
				</small>
			</td>
		</tr>
EOR

		if($row_class eq 'r' )
			{
			$row_class = 's'  ;
			}
		else
			{
			$row_class = 'r'  ;
			}
		}
		
	$html .= <<EOH ;
	</table>
</div>
EOH
	}
	
# remove all trace of javascript
$index =~ s{<script type="text/javascript">.*</script>}{}sm ; 
$index =~ s{\Q<body onload="render('')">}{}sm ;

$index =~ s{(<div class="box">.*?</div>)}{}sm ;
my $title = '' ;  #$1 ;

$index =~ s{<div class="box">.*?</div>}{}sm ;

$index =~ s{(</head>)}{$1\n$title\n$html}sm ;

my $pure_html_index_location = "$path/pure_html_index.html" ;

write_file $pure_html_index_location, $index ;

return $pure_html_index_location ;
}

#---------------------------------------------------------------------------------------------------------

sub get_module_distribution
{

=head2 get_module_distribution($cpan_mini, $mcd_cache, $module)

Finds the distribution containing the module.

  my $distribution = get_module_distribution($cpan_mini, $mcd_cache, $module) ;

I<Arguments>

=over 2 

=item $cpan_mini - Location of the CPAN::MINI repository

=item $mcd_cache - Location of the cache maintained by CPAN::Mini::ProjectDocs

=item $module - Name of the module to display

=back

I<Returns> - The location of the distribution containing the module to display

I<Exceptions> - read error if the cache is not already generated

=cut

my ($cpan_mini, $mcd_cache, $module) = @_ ;

my (undef, undef, $modules_details_cache_file) = get_mcd_paths($cpan_mini, $mcd_cache) ;
my $first_letter = substr($module, 0, 1) ;
my $cache_file = "${modules_details_cache_file}_$first_letter.txt" ;

my $module_details  = do $cache_file or carp "Error: Invalid '$cache_file'\n" ;;

my $distribution ;

for my $record ( @{$module_details->{entries}{entries}})
	{
	if($record->{'package name'} eq $module)
		{
		$distribution = "$cpan_mini/authors/id/$record->{'path'}" ;
		last ;
		}
	}

return $distribution ;
}

#---------------------------------------------------------------------------------------------------------

sub generate_cache
{

=head2 generate_cache($cpan_mini, $mcd_cache)

Checks the state of the B<CPAN::Mini::ProjectDocs> cache and regenerates it if necessary.

I<Arguments>

=over 2 

=item $cpan_mini - Location of the CPAN::MINI repository

=item $mcd_cache - Location of the cache maintained by CPAN::Mini::ProjectDocs

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($cpan_mini, $mcd_cache) = @_ ;

my ($modules_details_file, $modules_details_txt_md5_file, $modules_details_cache_file) = get_mcd_paths($cpan_mini, $mcd_cache) ;
my $modules_details_txt_md5 = get_file_MD5($modules_details_file) ;

if(-e $modules_details_txt_md5_file)
	{
	my  $mcd_cache_md5 = read_file($modules_details_txt_md5_file) ;
	
	if($mcd_cache_md5 ne $modules_details_txt_md5)
		{
		regenerate_cache($cpan_mini, $mcd_cache) ;
		}
	}
else
	{
	regenerate_cache($cpan_mini, $mcd_cache) ;
	}

return ;
}

#---------------------------------------------------------------------------------------------------------

sub regenerate_cache
{

=head2 regenerate_cache($cpan_mini, $mcd_cache)

Generates the B<CPAN::Mini::ProjectDocs> cache.

I<Arguments>

=over 2 

=item $cpan_mini - Location of the CPAN::MINI repository

=item $mcd_cache - Location of the cache maintained by CPAN::Mini::ProjectDocs

=back

I<Returns> - Nothing

I<Exceptions> - File sytem related errors if any

=cut

my ($cpan_mini, $mcd_cache) = @_ ;

warn "Generating cache.\n" ;

my ($modules_details_file, $modules_details_txt_md5_file, $modules_details_cache_file, $modules_details_cache_all_names) 
	= get_mcd_paths($cpan_mini, $mcd_cache) ;
	
my $modules_details_txt_md5 = get_file_MD5($modules_details_file) ;

my $module_details = CPAN::PackageDetails->read( $modules_details_file );

my $count = $module_details->count;
warn "$count records found.\n" ;

my $entries_lookup = {} ;
my @modules ;

my $entries  = $module_details->{entries};
my $records  = $entries->{entries};
for my $record ( @{$records})
	{
	push @modules, $record->{'package name'} ;
	
	my $first_letter = substr($record->{'package name'}, 0, 1) ;
	push @{$entries_lookup->{$first_letter}}, $record ;
	}

#----------------------------------

local $Data::Dumper::Purity = 1 ;
local $Data::Dumper::Indent = 0 ;

for(keys %{$entries_lookup})
	{
	$module_details->{entries}{entries} = $entries_lookup->{$_} ;
	write_file "${modules_details_cache_file}_$_.txt", Dumper($module_details) , "\n\$VAR1 ;\n" ;
	}

write_file $modules_details_cache_all_names, Dumper(\@modules), "\n\$VAR1 ;\n"  ;
write_file($modules_details_txt_md5_file, $modules_details_txt_md5) ;

return ;
}
	
#---------------------------------------------------------------------------------------------------------

sub search_modules
{

=head2 search_modules($cpan_mini, $mcd_cache, $module)

Matches I<$module> to all the modules in the CPAN mini repository and displays the match results.

I<Arguments>

=over 2 

=item $cpan_mini - Location of the CPAN::MINI repository

=item $mcd_cache - Location of the cache maintained by CPAN::Mini::ProjectDocs

=item $module - Name of the module to match

=back

I<Returns> - Nothing

I<Exceptions>

=cut

my ($cpan_mini, $mcd_cache, $module) = @_ ;

my ($modules_details_file, $modules_details_txt_md5_file, $modules_details_cache_file, $modules_details_cache_all_names) 
	= get_mcd_paths($cpan_mini, $mcd_cache) ;

my $modules = do $modules_details_cache_all_names or carp "Error: Invalid '$modules_details_cache_all_names'!\n";

for (@{$modules})
	{
	print "$_\n" if(/$module/i) ;
	}

#~ use Text::Soundex ;
#~ my $soundex =  soundex($module) ;

#~ for(@{$module_details->{entries}{entries}})
	#~ {
	#~ my $possible_package_soundex =  soundex($_->{'package name'}) ;
	
	#~ print "\t$_->{'package name'}\n" if $soundex eq $possible_package_soundex ;
	#~ }
	
return ;	
}
	
#---------------------------------------------------------------------------------------------------------

sub get_file_MD5
{

=head2 get_file_MD5($file)

Returns the MD5 of the I<$file> argument.

I<Arguments>

=over 2 

=item $file - The location of the file to compute an MD5 for

=back

I<Returns> - A string containing the file md5

I<Exceptions> - fails if the file can't be open

=cut

my ($file) = @_ ;
open(FILE, $file) or croak "Can't open '$file': $!";
binmode(FILE);
return Digest::MD5->new->addfile(*FILE)->hexdigest ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NH
	mailto: nadim@cpan.org

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPAN::Mini::ProjectDocs

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPAN-Mini-ProjectDocs>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-cpan-mini-projectdocs@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/CPAN-Mini-ProjectDocs>

=back

=head1 SEE ALSO

L<CPAN::Mini::Webserver>, elinks

=cut
