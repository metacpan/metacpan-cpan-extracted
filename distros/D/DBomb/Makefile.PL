use 5.008;
use ExtUtils::MakeMaker;
use File::Basename;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DBomb',
    'VERSION_FROM'	=> 'DBomb/Version.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DBomb.pm', # retrieve abstract from module
       AUTHOR     => 'millaway@cpan.org') : ()),

    'PREREQ_PM'		=> {map{$_=>0} qw(
        base
        Carp
        Carp::Assert
        Class::MethodMaker
        DBI
        Tie::Array
        Tie::IxHash)},
    'EXE_FILES' => [qw(dbomb-gen dbomb-regen)],
    'MAN1PODS'  => +{ 'dbomb-gen'   => "\$(INST_MAN1DIR)/dbomb-gen.1",
                      'dbomb-regen' => "\$(INST_MAN1DIR)/dbomb-regen.1" },

    'PM' => +{ map {$_ => "\$(INST_LIBDIR)/$_" }
        # Update with:  r!find DBomb/ DBomb.pm -name '*.pm'
        qw(

          DBomb/Conf.pm
          DBomb/Query.pm
          DBomb/Base.pm
          DBomb/Meta/TableInfo.pm
          DBomb/Meta/ColumnInfo.pm
          DBomb/Meta/Key.pm
          DBomb/Meta/HasMany.pm
          DBomb/Meta/HasA.pm
          DBomb/Meta/HasQuery.pm
          DBomb/Meta/OneToMany.pm
          DBomb/Query/LeftJoin.pm
          DBomb/Query/Expr.pm
          DBomb/Query/Join.pm
          DBomb/Query/Update.pm
          DBomb/Query/Limit.pm
          DBomb/Query/OrderBy.pm
          DBomb/Query/RightJoin.pm
          DBomb/Query/Text.pm
          DBomb/Query/Insert.pm
          DBomb/Query/GroupBy.pm
          DBomb/Query/Delete.pm
          DBomb/Base/Private.pm
          DBomb/Base/Defs.pm
          DBomb/Value/Key.pm
          DBomb/Value/Column.pm
          DBomb/Test/Util.pm
          DBomb/Test/Objects.pm
          DBomb/Generator.pm
          DBomb/GluedQuery.pm
          DBomb/Util.pm
          DBomb/DBH/Owner.pm
          DBomb/GluedUpdate.pm
          DBomb/Value.pm
          DBomb/Version.pm
          DBomb/Tie/PrimaryKeyList.pm
          DBomb.pm

        )},
);

