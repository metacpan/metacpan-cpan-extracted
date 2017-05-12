use ExtUtils::MakeMaker qw(prompt WriteMakefile);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


BEGIN: { require 5.004; }

sub check_dep {
    my ($usexml,$xml,$res);
    
    $usexml = 1;

    $xml = eval("use XML::Parser; 1");
    if (!defined $xml) {
        print <<THERE

You do not have XML::Parser installed.
XML::Parser is needed if you wish to use the WBXML compiler, but I can disable
this routine and remove the dependancy if you do not wish to install this
module.

THERE
;
        while ($res !~ /^(y|n|q)/i) {
            $res = prompt("Remove XML::Parser dependency? [Yes/No/Quit]:");
        }
        exit(1) if ($res =~ /^q/i);
        if ($res =~ /n/) {
            print <<THERE
Ok, leaving dependency in. Install XML::Parser before running 'make'
THERE
;
            $usexml = 1;
        } else {
            print <<THERE
Removing dependancy. You can re-enable this function by installing XML::Parser
at a later date and re-running this Makefile.PL
THERE
;
            $usexml = 0;
        }
    }
    
    if ($usexml) {
        $prereq =  { 'CGI' => '2.79',
                     'HTML::Parser' => '0',
                     'HTML::TokeParser' => '0',
                     'HTML::TableExtract' => '0',
                     'IO::Handle' => '0',
                     'IO::File' => '0',
                     'XML::Parser' => '0'};
    }else{
        remdep();
        $prereq =  { 'CGI' => '2.79',
                     'HTML::Parser' => '0',
                     'HTML::TokeParser' => '0',
                     'HTML::TableExtract' => '0',
                     'IO::Handle' => '0',
                     'IO::File' => '0'
                    }
    }
    
    return ($prereq);
    
}

sub remdep {
    my ($size);

    open(PM,"WML.pm") || die($!);
    open(TMP,">WML.tmp") || die($!);
    
    while (<PM>) {	
        $_ =~ s/^\$USEXMLPARSER=1;$/\$USEXMLPARSER=0;/;
        print TMP $_;
    }
    close(PM); close(TMP);
    
    open(PM,">WML.pm") || die($!);
    open(TMP,"<WML.tmp") || die($!);
    while (<TMP>) { print PM $_;}
    close(PM); close(TMP);
    unlink("WML.tmp");

}


WriteMakefile(
    'NAME'	=> 'CGI::WML',
    'VERSION_FROM' => 'WML.pm', # finds $VERSION
    'PREREQ_PM'    => &check_dep(),
    ($] ge '5.005') ? (
             'AUTHOR'       => 'Angus Wood <angus@z-y-g-o.com>, Andy Murren <amurren@users.sourceforge.net>',
             'ABSTRACT'     => 'Subclass CGI.pm for WML output',
         ) : (),
);





