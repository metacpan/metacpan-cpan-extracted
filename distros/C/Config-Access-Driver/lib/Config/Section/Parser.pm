#
# @author Bodo (Hugo) Barwich
# @version 2026-08-31
# @package Conig::Access::Driver
# @subpackage lib/Config/Section/Parser.pm

# This Module defines Classes to manage Data of an INI configuration section
#
#---------------------------------
# Requirements:
#
#---------------------------------
# Features:
#

use Config::Section::List;

#==============================================================================
# The Config::Section::Parser Package

package Config::Section::Parser;

sub fillListFromArray {
    my $seclist   = $_[0];
    my $rarrcntnt = $_[1];

    return 0
      if ( !defined $seclist || !$seclist->isa('Config::Section::List') );

    my $iln    = -1;
    my $ilncnt = scalar(@$rarrcntnt);

    return 0 if ( $ilncnt < 1 );

    my $cfgsec    = undef;
    my $scntntky  = "";
    my $scntntvl  = "";
    my $isqstrtps = -1;
    my $isqendps  = -1;
    my $ieqlps    = -1;
    my $icmtps    = -1;

  CONFIGLINE:
    for ( $iln = 0 ; $iln < $ilncnt ; $iln++ ) {

        # Check for comments
        $icmtps = index( $rarrcntnt->[$iln], '#' );

        if ( $icmtps > 0 ) {

            #print "cmt hit: '$icmtps'\n";

            $rarrcntnt->[$iln] =
              substr( $rarrcntnt->[$iln], 0, $icmtps );

            #print "cmt cleaned: '" . $rarrcntnt->[$iln] . "'\n";
        }
        elsif ( $icmtps == 0 ) {

            #print "cmt skip: '" . $rarrcntnt->[$iln] . "'\n";
            $rarrcntnt->[$iln] = "";
        }

        $rarrcntnt->[$iln] =~ s/^[[:space:]]+//;
        $rarrcntnt->[$iln] =~ s/[[:space:]]+$//;

        next CONFIGLINE if ( $rarrcntnt->[$iln] eq '' );

        $ieqlps    = index( $rarrcntnt->[$iln], '=' );
        $isqstrtps = index( $rarrcntnt->[$iln], '[' );
        $isqendps  = index( $rarrcntnt->[$iln], ']' );

        if (   $isqstrtps > -1
            && $isqendps > -1
            && !( $ieqlps > -1 && $isqstrtps > $ieqlps ) )
        {
            #It's a Section Header

            $rarrcntnt->[$iln] = substr(
                $rarrcntnt->[$iln],
                $isqstrtps + 1,
                $isqendps - $isqstrtps - 1
            );

            $rarrcntnt->[$iln] =~ s/^[[:space:]]+//;
            $rarrcntnt->[$iln] =~ s/[[:space:]]+$//;

            #print "sec hdr: '" . $rarrcntnt->[$iln] . "'\n";

            $cfgsec = $seclist->getConfigSectionbyName( $rarrcntnt->[$iln] );

            #Create a New Section
            $cfgsec = $seclist->Add( $rarrcntnt->[$iln] )
              unless ( defined $cfgsec );

        }
        else    #It's a Section Option Value
        {
            if ( $ieqlps > -1 ) {
                $rarrcntnt->[$iln] =~ s/([[:space:]]+)=/=/;
                $rarrcntnt->[$iln] =~ s/=([^\S\r\n]+)/=/;

                ( $scntntky, $scntntvl ) =
                  split( /=/, $rarrcntnt->[$iln], 2 );

                #print "opt - ky: '$scntntky'; vl: '$scntntvl'\n";
            }
            else    #It's an Array List
            {
                $scntntky = '';
                $scntntvl = $rarrcntnt->[$iln];
            }

            $scntntky = '' unless ( defined $scntntky );
            $scntntvl = '' unless ( defined $scntntvl );

            $cfgsec = $seclist->Add
              unless ( defined $cfgsec );

            if ( defined $cfgsec ) {
                if ( $scntntky ne '' ) {

                    #print "set '$scntntky' => '$scntntvl'\n";

                    $cfgsec->set( $scntntky, $scntntvl );
                }
                else    #It's an Array List
                {
                    $cfgsec->add($scntntvl);
                }
            }
        }    #if($isqstrtps > -1 && $isqendps > -1
             # && !($ieqlps > -1 && $isqstrtps > $ieqlps))
    }    #for($iln = 0; $iln < $ilncnt; $iln++)

    return 1;
}

sub buildStringFromList {
    my $seclist = $_[0];
    my $scntnt  = "";

    return 0
      if ( !defined $seclist || !$seclist->isa('Config::Section::List') );

    my $cfgsec    = undef;
    my $scfgsecnm = '';
    my $scfgky    = '';
    my $scfgvl    = '';
    my $icfgsec   = -1;
    my $icfgky    = -1;
    my $icfgsecnt = $seclist->getMetaObjectCount();
    my $icfgkycnt = -1;

    print "sec cnt: '$icfgsecnt'\n";

  CONFIGSECTION:
    for ( $icfgsec = 0 ; $icfgsec < $icfgsecnt ; $icfgsec++ ) {
        $cfgsec = $seclist->getMetaObject($icfgsec);

        next CONFIGSECTION if ( !defined $cfgsec );

        $scfgsecnm = $cfgsec->getName();

        print "sec nm: '$scfgsecnm'\n";

        if ( $scfgsecnm ne '' ) {
            $scntnt .= "[" . $scfgsecnm . "]\n";
        }
        elsif ( $icfgsecnt > 1 ) {
            $scntnt .= "[]\n";
        }

        $icfgkycnt = $cfgsec->getKeyCount();

        for ( $icfgky = 0 ; $icfgky < $icfgkycnt ; $icfgky++ ) {
            ( $scfgky, $scfgvl ) = $cfgsec->getKeyValue($icfgky);

            if ( $scfgky ne '' ) {
                $scntnt .= $scfgky . '=' . $scfgvl . "\n";
            }
            elsif ( $scfgvl ne '' ) {

                #The Value does not have a Key
                $scntnt .= $scfgvl . "\n";
            }
        }
    }    #for($icfgsec = 0; $icfgsec < $icfgsecnt; $icfgsec++)

    return $scntnt;
}

return 1;
