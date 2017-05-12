use strict;
use Getopt::Long;
use Carp;
use File::Spec;
use Data::Babel;

our $cmd_line="$0 @ARGV";
our %OPTIONS;

GetOptions (\%OPTIONS, 
            qw(help reread create show! check_schema! 
              ));
usage() if $OPTIONS{help};

sub usage {
print<<USAGE;

Usage: $0 [options]

Example script to manage Babel creation and maintenance. Babel
parameters are hardcoded.

Options
-------
  --help              Print this message
  --reread            Re-read configuration files and create new Babel
  --create            Create AutoDB and Babel 
  --show              Print Babel in readable form. negatable. default 'on'.
  --check_schema      Check that schema is non-redundant. negatable. default 'on'.

USAGE
;
exit;
}
	
my %DEFAULTS=
  (babel_name=>'test',show=>1,check_schema=>1,
   database=>'test',host=>'localhost',user=>$ENV{USER},password=>''
  );
# merge defaults into options (from command line processing)
@OPTIONS{keys %DEFAULTS}=values %DEFAULTS;

# open and possibly create AutoDB database
my %db_params=(create=>$OPTIONS{create},database=>$OPTIONS{database},host=>$OPTIONS{host},
	       user=>$OPTIONS{user},password=>$OPTIONS{password});
my $autodb=new Class::AutoDB(%db_params);
unless ($autodb->is_connected) {
  my $errstr='Cannot connect to AutoDB database using supplied credentials: '.
    join(', ',map {"$_=$OPTIONS{$_}"} (qw(database host user password)));
  confess $errstr;
}

# set autodb class attribute in Babel
Data::Babel->autodb($autodb);

# read Babel from database if it exists
my $babel=old Data::Babel($OPTIONS{babel_name});

# create new Babel if options require it or old Babel does not exist
if ($OPTIONS{create} || $OPTIONS{reread} || !$babel) {
  # idtypes, masters, maptables are names of configuration files that define 
  #   the Babel's component objects
  my $idtypes=File::Spec->catfile(qw(examples idtype.ini));
  my $masters=File::Spec->catfile(qw(examples master.ini));
  my $maptables=File::Spec->catfile(qw(examples maptable.ini));

  $babel=new Data::Babel
    (name=>$OPTIONS{babel_name},old=>$babel,
     idtypes=>$idtypes,masters=>$masters,maptables=>$maptables);
}
$babel->show if $OPTIONS{show};
if ($OPTIONS{check_schema}) {
  my @errors=$babel->check_schema;
  print @errors? join("\n",@errors): 'check_schema found no errors';
  print "\n";
}


