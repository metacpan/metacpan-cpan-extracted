#!/usr/local/bin/perl -w
#/*!
#  @file           MaxDBtest.pm
#  @author         MarcoP, ThomasS, GeroD
#  @ingroup        dbd::MaxDB
#  @brief          This package is a common set of routines for the DBD::MaxDB tests.
#
#\if EMIT_LICENCE
#
#    ========== licence begin  SAP
#
#    (c) Copyright 2001-2006 SAP AG
#
#    All rights reserved.
#
#    ========== licence end


#\endif
#*/
require 5.004;
{
    package MaxDBTest;
 
    $numTest = 0;
    
    sub checkMinimalKernelVersion($;$){
        my ($dbh, $reqVers) = @_;
        my $kernvers = $dbh->{"MAXDB_KERNELVERSION"};
        
        $reqVers =~ /^(\d+).(\d+)(.(\d+))?/; 
        
        my $reqmajor = $1;
        my $reqminor = $2;
        my $reqcl    = (defined $4)? $4 : 0;
        
        $reqVers = $reqmajor * 10000 + $reqminor *100 + $reqcl;

#        print "$kernvers >= $reqVers ($reqmajor, $reqminor, $reqcl)\n";
        
        if (   $kernvers >=  $reqVers) {
          return 1;
        }
    	  return 0;
    }

    sub Test($;$) {
        my $result = shift; my $str = shift || '';
        if (defined $result && $result eq "skipped" ){    
         printf("ok %d # SKIPPED %s\n", ++$numTest, $str);
        } else {
          printf("%sok %d%s\n", ($result ? "" : "not "), ++$numTest, $str);
        }  
        $result;
    }
    
    # Test and beginTest / endTest are not compatible [problem: incrementation of $numTest]
    # Test and beginTest / endTest are not compatible [problem: incrementation of $numTest]
    sub TestEnd($;$) {
        my $result = shift; my $str = shift || '';
        if (defined $result && $result eq "skipped" ){    
         printf("ok %d # SKIPPED %s\n", $numTest, $str);
        } else {
          printf("%sok %d%s\n", ($result ? "" : "not "), $numTest, $str);
        }  
        $result;
    }


    # @param [in] name of sub test case
    $success = 1;
    sub beginTest($) {
        my $name = shift;
        printf(" Test %d: %s\n", ++$numTest, $name);
        
        $success = 1;
        1;
    }
    
    sub fail() {
        $success = 0;
        1;
    }
    
    # @param [in] success
    sub endTest() {
        printf("%sok %d\n", ($success ? "" : "not "), $numTest);
        1;
    }

    # @param [in] string
    # @return 1 always
    sub loginfo($) {
        my $str = shift;
        print STDOUT "INFO: $str\n";
        return 1;
    }

    # @param [in] string
    # @return 1 always
    sub logwarning($) {
        my $str = shift;
        print STDERR "WARN: $str\n";
        return 1;
    }

    # @param [in] string
    # @return 1 always
    sub logerror($) {
        my $str = shift;
        print STDERR "ERROR: $str\n";
        fail();
        return 1;
    }

    # @param [in] data base handle
    # @param [in] SQL statement
    # @return 1 on success
    #         0 on error
    sub execSQL($;$) {
        my $dbh = shift or 0;
        my $SQL = shift;

        # exit if we have an undefined dbh
        if (!(defined $dbh) or !$dbh) { return 0; }

        # exit if we do not have a connection
        if (!$dbh->{'Active'}) { return 0; }

        # exit if no SQL string is set
        if (!(defined $SQL) or ($SQL eq '')) { return 0; }

        # store old PrintError-setting
        my $oldPE = $dbh->{'PrintError'};
        # disable PrintError
        $dbh->{'PrintError'} = 0;

        # execute SQL statement
        my $rc = $dbh->do(qq{ $SQL});

        # restore old PrintError-setting
        $dbh->{'PrintError'} = $oldPE;

        if ($rc) {
            return 1;
        }
        else {
            return 0;
        }
    }

    # @param [in] data base handle
    # @param [in] table name
    # @return 1 on success
    #         0 on error
    sub dropTable($;$) {
        my $dbh = shift;
        my $tablename = shift;

        my $result = execSQL($dbh, qq{DROP TABLE $tablename});
        return $result;
    }
    
    1;
}
