#!/usr/bin/perl -w

$disk = "disk1s9";
$tmplocation = "/Volumes/Test/testfile.tmp";
$iterations = 5;

# set the iterations to how many runs of iozone you want to do for each filesystem

$i = 0;
system("/usr/sbin/diskutil eraseVolume Ext2 Test $disk");

while ($i<$iterations)
	{
	print "Ext2 $disk - \#$i - " . scalar localtime() . "\n";
	system("/usr/local/bin/iozone -g 1G -+u -Rab $disk-noJournal-full-$i.wks -f $tmplocation > $disk-full-ext2-$i.log") ;
	system("/usr/sbin/diskutil eraseVolume Ext2 Test $disk");
	$i++;
	}
	

#Run the next set with hfs  
$i = 0;
system("/usr/sbin/diskutil eraseVolume HFS Test $disk");

while ($i<$iterations)
	{
	print "HFS \#$i" . scalar localtime() . "\n";
	system("/usr/local/bin/iozone -g 1G -+u -Rab $disk-Journal-full-$i.wks -f $tmplocation > $disk-full-hfs-$i.log");
	system("/usr/sbin/diskutil eraseVolume HFS+ Test $disk");
	$i++;

	}

#Run the next set with ufs
$i = 0;
system("/usr/sbin/diskutil eraseVolume UFS Test $disk");

while ($i<$iterations)
	{
	print "UFS \#$i" . scalar localtime() . "\n";
	system("/usr/local/bin/iozone -g 1G -+u -Rab $disk-Journal-full-$i.wks -f $tmplocation > $disk-full-ufs-$i.log");
	system("/usr/sbin/diskutil eraseVolume UFS Test $disk");
	$i++;

	}
	
#Run the next set with hfs+
$i = 0;
system("/usr/sbin/diskutil eraseVolume HFS+ Test $disk");

while ($i<$iterations)
	{
	print "HFS+ \#$i" . scalar localtime() . "\n";
	system("/usr/local/bin/iozone -g 1G -+u -Rab $disk-Journal-full-$i.wks -f $tmplocation > $disk-full-hfsplus-$i.log");
	system("/usr/sbin/diskutil eraseVolume HFS+ Test $disk");
	$i++;

	}

#Run the next set with hfs+ with journaling turned on  
$i = 0;
while ($i<$iterations)
	{
	print "Journaled - $disk - \#$i - " . scalar localtime() . "\n";
	system("/usr/sbin/diskutil enableJournal $disk");
	system("/usr/local/bin/iozone -g 1G -+u -Rab $disk-Journal-full-$i.wks -f $tmplocation > $disk-full-hfsplusJournal-$i.log");
	system("/usr/sbin/diskutil eraseVolume HFS+ Test $disk");
	$i++;

	}
system("/usr/sbin/diskutil DisableJournal $disk");
