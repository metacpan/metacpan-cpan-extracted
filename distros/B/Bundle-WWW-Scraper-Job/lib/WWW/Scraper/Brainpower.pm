
package WWW::Scraper::Brainpower;

#####################################################################
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(WWW::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.04 $ =~ /(\d+)\.(\d+)/);

use WWW::Scraper(qw(2.18 trimTags trimLFs removeScriptsInHTML cleanupHeadBody));
use WWW::Scraper::FieldTranslation(1.00);

my $scraperRequest = 
   { 
      'type' => 'QUERY'       # Type of query generation is 'QUERY'
      # This is the basic URL on which to build the query.
      ,'url' => 'http://www.brainpower.com/IndListProject.asp?'
      # This is the Scraper attributes => native input fields mapping
      ,'nativeQuery' => 'skills'
      ,'nativeDefaults' =>
                      {    'navItem' => 'searchProjects'  # This is a hidden field, presumably declares "search"
                          ,'submit1' => 1                 # This is the actual submit button.
                          #,'pageSize' => 100              # pageSize has no effect on Brainpower.com
                          ,'title'   => 'ALL'             # All job designations.
                          #,'title' => 'AP'               # Application Programmer.
                          ,'searchType' => 1              # searchType = ANY words.
                          ,'state'      => 80             # All US States
                          #,'state' => 5                  # California (North)
                          ,'rate' => ''
                      }
      ,'defaultRequestClass' => 'Job'
      ,'fieldTranslations' =>
              { '*' => 
                      {    'skills'    => 'skills'
                          ,'payrate'   => \&translatePayrate
                          ,'locations' => new WWW::Scraper::FieldTranslation('Brainpower', 'Job', 'locations')
                          ,'*'         => '*'
                      }
              }
      # Some more options for the Scraper operation.
     ,'cookies' => 1
   };

my $scraperFrame =
[ 'HTML', 
    [ 
        [ 'NEXT', 'Next&nbsp;' ]
       ,[ 'COUNT', 'Your search resulted in <b>([0-9,]+)</b> jobs.' ]
       ,[ 'BODY', '<!-- Begin Nested Right Table Cell -->', undef,
            [  
               [ 'TABLE', 
                 [
                   [ 'TABLE', 
                      [
                          [ 'TR' ]
                         ,[ 'TR' ]
                         ,[ 'HIT*', #'Job::Brainpower',
                             [ 
                                 [ 'TR', 
                                     [
                                         [ 'TD', [ [ 'A', 'url', 'jobID' ] ] ]
                                        ,[ 'TD' ] # There's a TD in a <!--COMMENT-->, here ! ! ! all are "Any Designation". E.G., <!--<TD><H6>&nbsp;&nbsp;&nbsp;&nbsp;TITLE</H6></TD>-->
                                        ,[ 'TD', 'skills' ]
                                        ,[ 'TD', 'payrate' ]
                                        ,[ 'TD', 'location' ]
                                     ]
                                 ]
                                ,[ 'TR' ]
                             ]
                          ]
#                         ,[ 'BOGUS', 1 ]  #Bogus result at the beginning . . .
                         ,[ 'BOGUS', -1 ] # and at the end!
                      ]
                   ]
                 ]
               ]
            ]
        ]
    ]
];            


    # scraperDetail describes the format of the detail page.
my $scraperDetail = 
[ 'TidyXML', \&cleanupHeadBody, \&removeScriptsInHTML, \&specialBrainpowerTreatment, 
    [ 
        ['XPath', '/html/body/table[3]/tr/td[7]/table/tr/td/table', 
            [  
                 ['XPath', 'tr[5]/td[2]',  'title',   \&trimTags, \&trimLFs]
                ,['XPath', 'tr[6]/td[2]',  'role',    \&trimTags, \&trimLFs]
                ,['XPath', 'tr[7]/td[2]',  'skills',  \&trimTags, \&trimLFs]
                ,['XPath', 'tr[8]/td[2]',  'jobType', \&trimTags, \&trimLFs]
                ,['XPath', 'tr[9]/td[2]',  'payrate', \&trimTags, \&trimLFs]
                ,['XPath', 'tr[10]/td[2]', 'jobLength', \&trimTags, \&trimLFs]
                ,['XPath', 'tr[11]/td[2]', 'city',    \&trimTags, \&trimLFs]
                ,['XPath', 'tr[12]/td[2]', 'state',   \&trimTags, \&trimLFs]
                ,['XPath', 'tr[13]/td[2]', 'postdate', \&trimTags, \&trimLFs]
                ,['XPath', 'tr[15]/td[2]', 'description', \&trimTags, \&trimLFs]
            ]
        ]
    ]
];


sub specialBrainpowerTreatment {
    my ($self, $hit, $xml) = @_;
    $$xml =~ s-\&reqid-\&amp;reqid-gsi;
    $$xml =~ s-\&resumeid-\&amp;resumeid-gsi;
    $$xml =~ s-\<mailto:-\&lt;mailto:-gsi;
    return $xml;
}

sub init {
    my ($self) = @_;
    $self->searchEngineHome('http://www.Brainpower.com');
    $self->searchEngineLogo('<IMG SRC="http://www.brainpower.com/images/logo_circ_01.gif">');
    return $self;
}


sub testParameters {
    my ($self) = @_;
    
    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return {
                 #'SKIP' => &WWW::Scraper::TidyXML::isNotTestable('Brainpower') #'Man, this one takes a long time!' #  
                 'SKIP' => "Brainpower has gone the login route: Scraper's not up to that yet, but here's the framework if you want to do it yourself."
                            # EVEN CAME UP WITH "3709Operation is not allowed on an object referencing a closed or invalid connection"! gdw.2003.01.16
                ,'TODO' => ''
                ,'testNativeQuery' => 'Perl'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 16
                ,'expectedBogusPage' => 3
                ,'usesPOST' => 1
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $scraperFrame }
sub scraperDetail{ $scraperDetail }

##############################################################
# The text in this <TD> element are four lines representing
# postDate, location, jobCategory and jobType. Parse that here.
sub parseLocation {
    my ($self, $hit, $dat) = @_;
    $dat = $self->trimLFLFs($hit, $dat);
    $dat =~ m/\n(.*?)\n(.*?)\n(.*?)\n(.*)/s;
    $hit->_elem('postDate', $1);
#    $self->_elem('location', $2);
    $hit->_elem('jobCategory', $3);
    $hit->_elem('jobType', $4);
    return $2;
}


###############################################
#
# nextURL - calculate the next page's URL.
#
# Here is the JavaScript that FlipDog uses to
# create it's "More Results" link. So it's
# pretty obvious what we need to do!
#
# var jobCount = 25;
# var jobStart = 1;
# var jobTotal = 221;
# function PageResults( bNext )
# {
# var szQS = "";
# if ( bNext )
# szQS = document.location.search.replace( /&job=\d+/, "" ) + "&job=" + String(jobStart + jobCount);
# else
# szQS = document.location.search.replace( /&job=\d+/, "" ) + "&job=" + String(jobStart - jobCount);
# location.href = "/js/jobsearch-results.html" + szQS;
# }
sub getNextPage {
    my ($self, $hit, $dat) = @_;
    
    return undef unless 
        $dat =~ m/var jobCount = (\d+).*?var jobStart = (\d+).*?var jobTotal = (\d+)/s;
    my ($jobCount, $jobStart, $jobTotal) = ($1,$2,$3);
    my $url = $self->{'_last_url'};
    $jobStart += $jobCount;
    return undef if $jobStart > $jobTotal; # (not represented in the JavaScript, but necessary)
    $url =~ s/\&job=(\d+)/\&job=$jobStart/;
    return $url;
}

# Translate from the canonical Request->payrate to Brainpower's 'rate' option.
sub translatePayrate {
    my ($self, $rqst, $val) = @_;
    return ('rate', $val);
}



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# Given a candidate hit, do post-selection.
# Return 1 to keep this hit, 0 to cast it away.
sub postSelect {
    my ($scraper, $rqst, $rslt) = @_;
    
    # Do the base postSelect, sans locations.
    return 0 unless $rqst->postSelect($scraper, $rslt, ['locations']);
    
    # Brainpower's too dumb to put the location in the results, we have to look at details!
    return $scraper->SUPER::postSelect($rqst, $rslt);
}


{ package WWW::Scraper::Response::Job::BrainpowerX;
use vars qw(@ISA);
@ISA = qw(WWW::Scraper::Response::Job);
use WWW::Scraper::Response::Job;

sub resultTitles {
    my $self = shift;
    my $resultT = {}; #$self->SUPER::resultTitles();
    
    # These fields are from the results page.
    $$resultT{'url'}      = 'url';
    $$resultT{'skills'}    = 'Skills';
    $$resultT{'jobID'}   = 'Job ID';
    $$resultT{'location'} = 'Location';
    
    return $resultT if $self->{'_scraperSkipDetailPage'};
    
    # The following fields come from the detail page.
    $$resultT{'role'}     = 'Role';
    $$resultT{'skillSet'} = 'Skill Set';
    $$resultT{'type'}     = 'Type';
    $$resultT{'payrate'}  = 'Payrate';
    $$resultT{'city'}     = 'City';
    $$resultT{'state'}    = 'State';
    $$resultT{'postDate'} = 'Post Date';
    $$resultT{'description'} = 'Description';

    return $resultT;
}

sub results {
    my $self = shift;
    my $results = {}; #$self->SUPER::results();
    
    # These fields are from the results page.
    $$results{'url'} = $self->url();
    $$results{'jobID'} = $self->jobID();
    $$results{'skills'} = $self->skills();
    $$results{'location'} = $self->location();
    $$results{'city'} = $self->city();
    return $results if $self->{'_scraperSkipDetailPage'};
    
    # The following fields come from the detail page.
    for ( qw(role skillSet type payrate state postDate description) ) {
        $$results{$_} = $self->$_();
    }
    return $results;
}

sub location { my $x = $_[0]->SUPER::location(); $x =~ s/\s+$//g; return $x;}

sub description { my $rslt = $_->SUPER::description();
# Hey, if some of those bubble-heads at the KBDs want to put in a few hundred spaces, then !%^&!* them!
    $rslt =~ s/\s+/ /g;
# The same goes for massive doses of <br>s. What is it with these people?
    $rslt =~ s/\n+/\n/g;
    return $rslt;
 }

}


1;
__END__

=pod

=head1 NAME

WWW::Scraper::Brainpower -  Scrapes Brainpower.com


=head1 SYNOPSIS

    use WWW::Scraper;
    use WWW::Scraper::Response::Job;

    $search = new WWW::Scraper('Brainpower');

    $search->setup_query($query, {options});

    while ( my $response = $scraper->next_response() ) {
        # $response is a WWW::Scraper::Response::Job.
    }

=head1 DESCRIPTION

Brainpower extends WWW::Scraper.

It handles making and interpreting Brainpower searches of F<http://www.Brainpower.com>.


=head1 OPTIONS

=over 8

=head2 title

=over 8

=item ALL => Any Designation

=item AP  => Application Programmer                            

=item BA  => Business Analyst                                  

=item CS  => Communications Programmer                         

=item DBA => DataBase Administrator                            

=item DSP => DataBase Programmer                               

=item GCD => Graphic Designer                                  

=item HAD => Hardware/ASIC Programmer                          

=item JD  => Java Developer                                    

=item LAN => LAN/Network Administrator                         

=item PML => Project Manager/leader                            

=item QAT => Quality Assurance/Tester                          

=item SPS => Systems Programmer                                

=item SYA => Systems Administrator                             

=item TR  => Technical Recruiter                               

=item TW  => Technical Writer                                  

=item WEB => Web Developer                                     

=back

=head2 skills

This is the query string. You do not explicitly set this; it's set by Scraper.

=head2 searchType

A RADIO button.

=over 8

=item 0 - All of the words

=item 1 - Any of the words

=back

=head2 rate

Hourly rate, limit 3 digits. Optional.

=head2 state (MULTIPLE - maximum 5 states)

=over 8

=item 80 => All US States                                     

=item 1 => Alabama                                           

=item 2 => Alaska                                            

=item 3 => Arizona                                           

=item 4 => Arkansas                                          

=item 5 => California(North)                                 

=item 6 => California(South)                                 

=item 7 => Colorado                                          

=item 8 => Connecticut                                       

=item 9 => Delaware                                          

=item 10 => District of Columbia                              

=item 11 => Florida                                           

=item 12 => Georgia                                           

=item 13 => Hawaii                                            

=item 14 => Idaho                                             

=item 15 => Illinois                                          

=item 16 => Indiana                                           

=item 17 => Iowa                                              

=item 18 => Kansas                                            

=item 19 => Kentucky                                          

=item 20 => Louisiana                                         

=item 21 => Maine                                             

=item 22 => Maryland                                          

=item 23 => Massachusetts                                     

=item 24 => Michigan                                          

=item 25 => Minnesota                                         

=item 26 => Mississippi                                       

=item 27 => Missouri                                          

=item 28 => Montana                                           

=item 29 => Nebraska                                          

=item 30 => Nevada                                            

=item 31 => New Hampshire                                     

=item 32 => New Jersey                                        

=item 33 => New Mexico                                        

=item 34 => New York                                          

=item 35 => North Carolina                                    

=item 36 => North Dakota                                      

=item 37 => Ohio                                              

=item 38 => Oklahoma                                          

=item 39 => Oregon                                            

=item 40 => Pennsylvania                                      

=item 41 => Rhode Island                                      

=item 42 => South Carolina                                    

=item 43 => South Dakota                                      

=item 44 => Tennessee                                         

=item 45 => Texas                                             

=item 46 => Utah                                              

=item 47 => Vermont                                           

=item 48 => Virginia                                          

=item 49 => Washington                                        

=item 50 => West Virginia                                     

=item 51 => Wisconsin                                         

=item 52 => Wyoming                                           

=back

=head1 AUTHOR

C<WWW::Scraper::Brainpower> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


