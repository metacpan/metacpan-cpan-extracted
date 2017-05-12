use Data::JavaScript::LiteObject;

while( @user = getpwent() ){
    $users{$user[0]} = {
	uid=>$user[2],
	gid=>$user[3],
	real=>$user[6],
	home=>$user[7],
	shell=>$user[8]};
}

print jsodump(protoName=>"user",
	      dataRef=>\%users);
                        
print jsodump(protoName=>"user",
	      explode=>1,
	      lineIN=>4,
	      listObjects=>"users",
	      dataRef=>\%users);
