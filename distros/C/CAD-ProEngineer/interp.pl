
use lib qw(../ProEngineer/blib/arch ../ProEngineer/blib/lib);
use CAD::ProEngineer;
use Devel::Peek;
use Data::Dumper;


# $CAD::ProEngineer::Verbose = 1;
print "hello world", "\n";
user_initialize();


sub display_model_info {
  my $err;
  my $o = new CAD::ProEngineer;
  my $mdl = new CAD::ProEngineer::ProMdl;
  my $mi = $mdl->ProMdlToModelitem;

  print "mdl: $mdl", "\n";
  print "mi: $mi", "\n";

  my %AD = ( "ABC" => 123, "DEF" => 456 );


  my $str;
  $str = sprintf("Model: %s.%s  Type: %d  SessionID: %d  ID: %d"
                 . "  Win: %d  Mod: %d", $mdl->NameGet, $mdl->ExtensionGet, 
                 $mdl->TypeGet, $mdl->SessionIdGet, $mdl->IdGet, 
                 $mdl->WindowGet, $mdl->ModificationVerify);

  $o->ProMessageDisplay("msg_file.txt", "USER %0s", $str);


  # Parameter visit function using named subroutine references
  #
  # $o->ProParameterVisit($mi, \&param_visit_filter, 
  #                       \&param_visit_action, \%AD);


  # Dimension visit function using named subroutine references
  #
  # $err = $o->ProSolidDimensionVisit($mdl, $o->PRO_B_FALSE, 
  #                                   \&dim_visit_action, undef, \%AD);


  # Dimension visit function using anonymous subroutine references
  #
  #   Note that the lexical variable $counter is visible to the 
  #   anonymous subroutine as a local scalar.
  #
  my $counter = 0;
  my $filter_ref = sub { return $o->PRO_TK_NO_ERROR };
  my $action_ref = sub {
        my $o = new CAD::ProEngineer;
        my $name = $o->ProDimensionSymbolGet($_[0]);
        my $val = $o->ProDimensionValueGet($_[0]);
        $o->ProMessageDisplay("msg_file.txt", "USER %0s", "dim: $name = $val");
        # $o->ProMessageClear;
        $counter++;
        return $o->PRO_TK_NO_ERROR;
      };
  $err = $mdl->ProSolidDimensionVisit($o->PRO_B_FALSE, $action_ref, 
                                      $filter_ref, \%AD);

  print "visit done, found $counter dimensions", "\n";


  print "End of display_model_info()", "\n";
  print "\n";
}


sub dim_visit_action {
  my $o = new CAD::ProEngineer;
  # print "action args (", scalar(@_), "): ",join('|',@_),"\n";

  my $name = $o->ProDimensionSymbolGet($_[0]);
  my $val = $o->ProDimensionValueGet($_[0]);
  # print " dim: $name = $val ", "\n";

  $o->ProMessageDisplay("msg_file.txt", "USER %0s", "dim: $name = $val");
  $o->ProMessageClear;
  return $o->PRO_TK_NO_ERROR;
}


sub param_visit_action {
  my $o = new CAD::ProEngineer;
  print "action args (", scalar(@_), "): ",join('|',@_),"\n";

  my $paramval = $o->ProParameterValueGet($_[0]);
  my $name = $o->ProParameterNameGet($_[0]);
  my $val = $o->ProParamvalueValueGet($paramval);

  print $_[0], " name: $name   val: $val ", $_[2], "\n";
  $o->ProMessageDisplay("msg_file.txt", "USER %0s", "parameter: $name = $val");
  # $o->ProMessageClear;
  return $o->PRO_TK_NO_ERROR;
}


sub param_visit_filter {
  my $o = new CAD::ProEngineer;
  print "filter args (", scalar(@_), "): ",join('|',@_),"\n";
  return $o->PRO_TK_NO_ERROR;
}


sub user_initialize {
  my($ui_err);
  my $o = new CAD::ProEngineer;

  $o->ProMessageDisplay("msg_file.txt", "USER %0s", "Hello world!");


  # Defining a new UICmdAction and specifying an anonymous subroutine 
  # with a reference to a scalar.  The reference will be passed to 
  # display_model_info().
  #
  my($test) = 1;
  $ui_err = $o->ProCmdActionAdd("Stuff", sub { display_model_info(\$test) }, 
                                $o->uiProeImmediate, $o->ACCESS_AVAILABLE, 
                                $o->PRO_B_TRUE, $o->PRO_B_TRUE, $cmd_id);



  # Registering UICmdAction on the "Utilities" menu.
  #
  $ui_err = $o->ProMenubarmenuPushbuttonAdd("Utilities", "Stuff", "Stuff", 
                                            "Special stuff commands",
                                            "Utilities.psh_util_aux", 
                                            $o->PRO_B_TRUE, $cmd_id, 
                                            "msg_file.txt");

}


# END blocks are not executed when the interpreter shuts down
#
END {
  print "END reached.", "\n";
}



