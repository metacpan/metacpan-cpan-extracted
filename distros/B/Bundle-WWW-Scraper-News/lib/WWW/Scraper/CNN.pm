use strict;

package WWW::Scraper::CNN;

use vars qw($VERSION @ISA);
@ISA = qw(WWW::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.00 $ =~ /(\d+)\.(\d+)/);

use WWW::Scraper(qw(1.24 generic_option addURL trimTags trimLFs));

my $scraperRequest = 
   { 
      'type' => 'GET'
     ,'formNameOrNumber' => 0
     ,'submitButton' => undef

     # This is the basic URL on which to build the query.
     ,'url' => 'http://cnn.looksmart.com/r_search?'
     #qc=&col=cnni&qm=0&st=1&nh=10&lk=1&rf=1&look=&venue=all&keyword=&qp=&comefrom=izch&isp=zch&search=0&key=Infospace
     ,'nativeQuery' => 'key'
     ,'nativeDefaults' => {
                             'qc' => ''
                            ,'col' => 'cnn'
                            ,'qm' => '0'
                            ,'st' => '1'
                            ,'nh' => '10'
                            ,'lk' => '1'
                            ,'rf' => '1'
                            ,'look' => ''
                            ,'venue' => 'all'
                            ,'keyword' => ''
                            ,'qp' => ''
                            ,'comefrom' => 'izch'
                            ,'isp' => 'zch'
                            ,'search' => '0'
                            ,'key' => undef
                          }
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    '*'             => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
      [ 'HTML', 
         [  
            [ 'HIT*' , 'News', 
               [  
                    [ 'DL',
                        [
                            [ 'DT', [ [ 'AN', 'url', 'Title' ] ] ]
                           ,[ 'DD', 'Description' ]
                        ]
                     ]
               ]
            ]
         ] 
      ];


my $scraperDetail =
      [ 'HTML', 
         [  
            [ 'BODY', '<html>', '</html>',
            [
                [ 'HIT' , 
                   [  
                        [ 'F', \&get_authors, 'authors']
                       ,[ 'F', \&get_description, 'description']
                       ,[ 'F', \&get_text, 'text', 'dateline', 'source']
                       ,[ 'F', \&get_section, 'section']
                       ,[ 'F', \&get_sub_section, 'sub_section']
                       ,[ 'F', \&get_creation_date, 'creation_date' ]
                       ,[ 'F', \&get_title, 'title']
                       ,[ 'F', \&get_posted, 'posted']
                   ]
                ]
            ]
            ]
         ] 
      ];



# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $scraperFrame }
sub scraperDetail{ $scraperDetail }




sub testParameters {
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    my $isNotTestable = WWW::Scraper::isGlennWood()?0:'No testParameters provided.';
    return { 
             'SKIP' => $isNotTestable
            ,'testNativeQuery' => 'NASA'
            ,'expectedOnePage' => 9
            ,'expectedMultiPage' => 100
            ,'expectedBogusPage' => 0
           };
}









sub get_authors {
   my ($self, $hit, $dat) = @_;
#	my ($self, $cs, $ds) = @_;
	$dat =~ m{<meta name="AUTHOR" content="(.*?)">}si;
return ($1);
}

sub get_description {
   my ($self, $hit, $dat) = @_;
#	my ($self, $cs, $ds) = @_;
	$dat =~ m{<meta name="DESCRIPTION" content="(.*?)">}si;
return ($1);

}

sub get_text {
    my ($self, $hit, $dat) = @_;
#	my ($self, $cs, $ds) = @_;
	my $text = '';
    # preserve the <p> tags here for _get_dateline()
    $text = join '', ($dat =~ m{\n(<p>.*?</p>)}gsi);
    my ($dateline, $source) = $self->_get_dateline(\$text);
return ($text,$dateline,$source);
}

sub _get_dateline {
    my ($self, $text) = @_;
    # <P><a href="map.nevada.las.vegas.jpg">LAS VEGAS, Nevada</a> (IDG) --
    my $dtln = $1 if ( $$text =~ s{<[pbPB]>\s*([^-<]*?)\s*--}{}s );
    # Doing the tripTags before the above regex would allow us to capture datelines with <A>
    #  anchors in them, but we need a trimTags() that preserves selected tags to make that work.
    #  (or a much more elaborate regex here!)
    $dtln = $self->trimTags(undef, $dtln);
    my ($dateline, $source) = ($2,$3) if ( $dtln =~ m{^\s*(([^-<(]*)\s+)?\((\w+)\)$}s );
    unless ( $source ) {
        # <b>HONG KONG, China --</b>  
        ($dateline, $source) = ($1,$2) if ( $dtln =~ m{^\s*([^,]+)?\s*,\s*([^\s-]+)}s );
    }
    return ($dateline, $source);
}

sub get_section {
    my ($self, $hit, $dat) = @_;
#	my ($self, $cs, $ds) = @_;
	my ($section) = ($dat =~ m{<meta name="SECTION" content="(.*?)">}si);
    unless ( $section ) {
        $section = $1 if $dat =~ m{/([^.]+)\.([^.]+)\.story.gif};
    }
    unless ( $section ) {
        $section = $1 if $dat =~ m{<SPAN CLASS="Bnr1">\s*(\w+)\s*>?</SPAN>}s;
    }
return ($section);
}

sub get_sub_section {
    my ($self, $hit, $dat) = @_;
#	my ($self, $cs, $ds) = @_;
	my ($sub_section) = ($dat =~ m{<meta name="SUBSECTION" content="(.*?)">}si);
    unless ( $sub_section ) {
        $sub_section = $2 if $dat =~ m{/([^.]+)\.([^.]+)\.story.gif}s;
    }
    unless ( $sub_section ) {
        $sub_section = $1 if $dat =~ m{<SPAN CLASS="Bnr2">\s*(\w+)\s*>?</SPAN>}s;
    }
return ($sub_section);
}

sub get_title {
    my ($self, $hit, $dat) = @_;
#	my ($self, $cs, $ds) = @_;
    #<title>CNN.com - On September 11, final words of love - September  9, 2002</title>
    my ($title) = ($dat =~ m{<title>(.*?)</title>}si);
    $title =~ s{[\w.]+\s+\d+,\s+\d\d\d\d$}{};
    unless ( $title ) {
        ($title) = ($dat =~ m{<h1>(.*?)</h1>}si);
    }
return ($title);
}

sub get_creation_date {
    my ($self, $hit, $dat) = @_;
#	my ($self, $cs, $ds) = @_;
	$dat =~ m{<meta name="(publicationDate|DATE)" content="(.*?)">}si;
    my $date = $2;
    # or <META NAME="date" CONTENT="<!-- CNN date -->"> ? ? ?
    unless ( $date =~ m{^\d\d\d\d-\d\d-\d\d} ) {
        ($date) = m{<p class="timestamp">([\w\.]+\s+\d+,\s+\d\d\d\d)}si;
    }
    unless ( $date ) {
        my ($title) = ($dat =~ m{<title>(.*?)</title>}si);
        ($date) = ($title =~ m{([\w\.]+\s+\d+,\s+\d\d\d\d)$});
    }
    return ($date);
}

sub get_posted {
    my ($self, $hit, $dat) = @_;
    #document.write('<p><span class="Small">September  6, 2002 Posted: 0837 GMT<br><\/span><\/p>')
    my ($postedPre, undef, $postedPost) = ($dat =~ m{document\.write\('<p><span class="Small">(\w+\s+\d+,\s+\d\d\d\d)(\s+Posted:\s+)(\d\d\d\d\s+\w+)<br>'}s);
    unless ( $postedPre and $postedPost ) {
        # older docs: <p><span class="Small">August 6, 2001 Posted: 1603 GMT<br></span></p>
        ($postedPre, undef, $postedPost) = ($dat =~ m{<p><span class="Small">(\w+\s+\d+,\s+\d\d\d\d)(\s+Posted:\s+)(\d\d\d\d\s+\w+)<br>}s);
    }
    unless ( $postedPre and $postedPost ) {
        #<p class="timestamp">March 1, 2001<br> Web posted at: 1432 GMT</p>
        #<p class="timestamp">April 24, 2001<br> Web posted at: 1540 GMT</p>
        ($postedPre, undef, $postedPost) = ($dat =~ m{<p\s+class="timestamp">([\w\.]+\s+\d+,\s+\d\d\d\d)(<br> Web posted at:\s+)(\d\d\d\d\s+\w+)</p>}si);
        }
    # MORE: older documents.
    #<p><FONT FACE="Verdana, Arial, Helvetica, sans-serif" SIZE="1" color="#333333"><i><b>January 10, 2000</b><br>
    # Web posted at: 10:57 a.m. EST (1557 GMT)</i></font></p>
    
    return "$postedPre $postedPost" if ( $postedPre and $postedPost );
    return undef;
}
    
sub is_OK {
	my ($self, $cs, $ds) = @_;

	return (1, 'Registration Required')
		if ($ds->{'content'} =~ m{<title>Please register</title>}si);

	unless($ds->{content} =~ m{<div class="content">}si) {
		return (99, 'Unknown Error');
	}

	return (0);
}

