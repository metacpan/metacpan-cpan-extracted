#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_MergeEntry.pl,v 1.2 2007/07/20 19:57:59 jeffmurphy Exp $
#
# NAME
#   ars_MergeEntry.pl [server] [user] [password] [schema] [diaryfieldname] 
#             [entryid]
#
# DESCRIPTION
#   open the named schema and retrieve the contents of the diary field
#   for the specified entryid. if the diary field contains entries, 
#   change the first entry and merge it back into the record.
#
# AUTHOR
#   jeff murphy
#
# $Log: ars_MergeEntry.pl,v $
# Revision 1.2  2007/07/20 19:57:59  jeffmurphy
# minor doc edits
#
# Revision 1.1  1998/02/09 17:57:04  jcmurphy
# Initial revision
#
#
#

use ARS;

($S, $U, $P, $SC, $DF, $EID) = (shift, shift, shift, shift, shift, shift);

if($EID eq "") {
    print "Usage: $0 [server] [user] [password] [schema] [diaryfieldname]
            [entryid]\n";
    exit 0;
}

($c = ars_Login($S, $U, $P)) ||
    die "ars_Login: $ars_errstr";

($fid = ars_GetFieldByName($c, $SC, $DF)) ||
    die "ars_GetFieldByName: $ars_errstr";

(%val = ars_GetEntry($c, $SC, $EID, $fid)) ||
    die "ars_GetEntry: $ars_errstr";

printf("Diary field \"$DF\" contains %d entries.\n\n",
       $#{$val{$fid}});

print "First entry is:\n\n";

print "time  = ".localtime(${$val{$fid}}[0]->{timestamp})."\n";
print "user  = ".${$val{$fid}}[0]->{user}."\n";
print "value = ".${$val{$fid}}[0]->{value}."\n";

print "\nAppending \"Foobar!\" to first entry.\n";

${$val{$fid}}[0]->{value} .= " Foobar!";

print "Constructing encoded diary.\n";

($encodedDiary = ars_EncodeDiary(@{$val{$fid}})) ||
    die "ars_EncodeDiary failed";

print "Merging entry back into database.\n";

# see html doc page for explanation of numeric flags.
# http://www.arsperl.org/manual/ars_MergeEntry.html

#        ... mergeType=4, eid-fid, entryid, diary-fid, encoded-diary
($eid = ars_MergeEntry($c, $SC, 4, 1, $EID, $fid, $encodedDiary)) ||
    die "ars_MergeEntry: $ars_errstr";

ars_Logoff($c);
exit(0);

