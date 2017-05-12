print "1..1\n";

eval "use Apache::LoadAvgLimit::GetAvg;";

print "not " if $@;
print "ok 1\n";
