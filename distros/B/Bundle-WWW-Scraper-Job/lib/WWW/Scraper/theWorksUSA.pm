
package WWW::Scraper::theWorksUSA;

=pod

=head1 NAME

WWW::Scraper::theWorksUSA - Scrapes theWorksUSA


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('theWorksUSA');


=head1 DESCRIPTION

This class is an extends WWW::Scraper to www.theWorksUSA.com.
It handles making and interpreting theWorksUSA searches
F<http://www.theWorksUSA.com>.

THIS ONE IS NOT DEBUGGED - IT GOES INTO LOOPS AND DOESN'T COME BACK.

=head1 OPTIONS

None at this time (2001.06.06)

=head1 AUTHOR

C<WWW::Scraper::theWorksUSA> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.02 $ =~ /(\d+)\.(\d+)/);

use WWW::Scraper(qw(1.48 generic_option addURL trimTags));
use strict;

my $scraperRequest = 
   { 
      'type' => 'FORM'
     ,'formNameOrNumber' => undef
     ,'submitButton' => undef

     # This is the basic URL on which to build the query.
     ,'url' => 'http://www.theworksusa.com/template/jobsearch/jobsearch.cfm?appid=1'
     # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'UserQuery'
     ,'nativeDefaults' => {}
     ,'defaultRequestClass' => 'Job'
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    '*'             => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 1
   };

my $scraperFrame =
        [ 'HTML', 
          [ 
            [ 'COUNT', '>(\d+)</font> matching record' ]
           ,[ 'NEXT', 2, \&getNextPage ]
           ,[ 'TABLE', '#0',
              [
                [ 'TR', '#0' ] # The first row is column titles.
               ,[ 'HIT*' , 'Job',
                  [  
                    [ 'TD', 'relevance', \&trimLFs ]
                   ,[ 'TD', 'company',   \&trimLFs ]
                   ,[ 'TD', [ [ 'A', 'url', 'title', \&trimLFs ] ] ] 
                   ,[ 'TD', 'salary',   \&trimLFs ]
                   ,[ 'TD', 'location', \&trimLFs ]
                   ,[ 'TD', 'postDate', \&trimLFs ]
                  ]
                ]
              ] 
            ] 
          ]
        ];


sub testParameters {
    return { 'SKIP' => 'theWorksUSA still has a known problem (looping).' };
}



# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }

# theWorksUSA does not have a NEXT button!
# We need to get the next page via the 1.2.3.4... menu.
sub getNextPage {
    my ($self, $hit, $dat) = @_;
    my $url = $self->{'_last_url'};
    $url =~ m/CurrentPage=(\d+)/;
    my $pgNum = $1 + 1;
    $url =~ s/CurrentPage=(\d+)/CurrentPage=$pgNum/;
    return $url;
}

sub trimLFs { # Strip LFs, then tag clutter from $_;
    my ($self, $hit, $dat) = @_;
    $dat =~ s/\n//gs;
   # This simply rearranges the parameter list from the datParser form.
    return $self->trimTags($hit, $dat);
}

sub trimLFLFs { # Strip double-LFs, then tag clutter from $_;
    my ($self, $hit, $dat) = @_;
    while ( $dat =~ s/\n\n/\n/s ) {}; # Do several times, rather than /g, to handle triple, quadruple, quintuple, etc.
   # This simply rearranges the parameter list from the datParser form.
    return $self->trimTags($hit, $dat);
}

1;
