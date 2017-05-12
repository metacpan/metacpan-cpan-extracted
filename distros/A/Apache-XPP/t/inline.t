BEGIN {
	eval "use Filter::Util::Call;";
	if ($@) {
		print "1..0\n";
		exit;
	}
}

use Apache::XPP::Inline;
1..2
<?= "ok 1" ?>
<?xpp print "ok 2"; ?>
