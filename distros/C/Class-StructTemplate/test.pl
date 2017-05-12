use manager;
use manager2;

$my_man2 = new manager (name=>'Heikowu',user=>'heikoman',passwd=>['I',['am'],'fine']);
$my_man4 = new manager2 (name=>'hello',user=>'abc',passwd=>$my_man2);
$my_man5 = new manager2 (name=>'hello2',user=>'abcd',passwd=>$my_man2);

$my_man4->save();
$my_man5->save();

($my_man3) = $my_man4->load("name='hello'");

print $my_man3->passwd->name."\n";
print $my_man3->passwd->user."\n";
print $my_man3->name."\n";

$my_man3->delete();
