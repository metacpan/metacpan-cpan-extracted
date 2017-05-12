use ExtUtils::MakeMaker qw(prompt WriteMakefile);

#--- Check for required modules ---

my $reqs_found=1;
my $missing=0;

sub check_module {
  my($module,$version) = @_;
  print substr("$module ............................",0,30);
  my $ok = eval {
    my $file = $module;
    $file =~ s#::#/#g;
    require $file . ".pm";
    $module->VERSION($version) if defined $version;
    1;
  };
  $missing++ unless $ok;
  print $ok ? "ok\n" : "** FAILED **\n$@\n";
  $ok;
}

print "\nChecking for installed modules\n\n";

unless (check_module('XML::DOM',1.25)) {
  $reqs_found=0;
  print <<"EDQ","\n";
AddressBook requires XML::DOM version 1.25 or later.
EDQ
}  

unless (check_module('Date::Manip',5.39)) {
  $reqs_found=0;
  print <<"EDQ","\n";
AddressBook requires Date::Manip version 5.39 or later.
EDQ
}

check_module('Net::LDAP',0.20) or print <<"EDQ","\n";
The LDAP and LDIF backends require Net::LDAP version 0.20 or later.
Installation may continue, however attempts to use LDAP or LDIF address books
will fail.
EDQ

check_module('DBI',1.14) or print <<"EDQ","\n";
The DBI-based backends require DBI version 1.14 or later.
Installation may continue, however attempts to use DBI-based address 
books (e.g mysql,csv, etc...) will fail.
EDQ

check_module('PDA::Pilot') or print <<"EDQ","\n";
The PDB (PalmOS) backend requires PDA::Pilot.
Installation may continue, however attempts to use Palm0S address
books will fail.  

PDA::Pilot is available as part of the pilot-link distribution.
EDQ

print "\n",<<"EDQ","\n" if $missing;
****************************************************************************
You are missing some modules that may be needed for the modules in Abook
to work correctly. Read the above messages and download any required
modules from http://www.perl.com/CPAN
****************************************************************************
EDQ

exit unless $reqs_found;

$r = prompt("For testing the LDAP backend, I need to know some things about 
your LDAP server.  Continue? [y/n]","y");

if ($r =~ /^y$/i) {
  $hostname = prompt("What is your LDAP server hostname","localhost");
  $base = prompt("What is a valid LDAP base that I can use for searching? 
(eg. \"ou=abook,dc=<your_domain>\")");
  $objectclass = prompt("What is a valid LDAP objectclass that I can search for?",
"organizationalUnit");
  print "The LDAP test script will attempt to bind anonymously to \"$hostname\"
and search for \"objectclass=$objectclass\" 
using the base: $base\n";
  open F, ">t/t.ldap.conf";
  print F << "EDQ";
<AddressBook_config>
  <fields>
    <field name="objectclass">
      <db type="LDAP" name="objectclass" />
    </field>
  </fields>
  <databases>
    <LDAP
      hostname = "$hostname"
      base = "$base"
      anonymous = "1"
      objectclass = "$objectclass"
    />
  </databases>
</AddressBook_config>
EDQ
  close F;
}

WriteMakefile(
    'NAME'	=> 'AddressBook',
    'VERSION_FROM' => 'lib/AddressBook.pm',
);

sub MY::postamble {
'
htmldocs :: 
	find lib -name *.pm | sed s/.pm$$// |sed s/^lib.// | xargs -i# pod2html --podroot=. --podpath=lib --infile=lib/#.pm --outfile=html/#.html 
'
}
