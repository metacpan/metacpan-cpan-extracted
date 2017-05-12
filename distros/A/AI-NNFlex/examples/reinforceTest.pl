# this is /really/ experimental - see perldoc NNFlex::reinforce
use AI::NNFlex;

my $object = AI::NNFlex->new([{"nodes"=>2,"persistent activation"=>0,"decay"=>0.0,"random activation"=>0,"threshold"=>0.0,"activation function"=>"tanh","random weights"=>1},
                        {"nodes"=>2,"persistent activation"=>0,"decay"=>0.0,"random activation"=>0,"threshold"=>0.0,"activation function"=>"tanh","random weights"=>1},
                       {"nodes"=>1,"persistent activation"=>0,"decay"=>0.0,"random activation"=>0,"threshold"=>0.0,"activation function"=>"linear","random weights"=>1}],{'random connections'=>0,'networktype'=>'feedforward', 'random weights'=>1,'learning algorithm'=>'reinforce','learning rate'=>.3,'debug'=>[],'bias'=>1});


$object->run([1,0]);
$output = $object->output();
foreach (@$output)
{
	print "1,0 - $_ ";
}
print "\n";

$object->run([0,1]);
$err = $object->learn([1]);
$output = $object->output();
foreach (@$output)
{
	print "0,1 - $_ ";
}
print "\n";


$object->run([0,1]);
$err = $object->learn([1]);
$output = $object->output();
foreach (@$output)
{
	print "0,1 - $_ ";
}
print "\n";

$object->run([0,1]);
$output = $object->output();
foreach (@$output)
{
	print "0,1 - $_ ";
}
print "\n";



$object->run([1,0]);
$output = $object->output();
foreach (@$output)
{
	print "1,0 - $_ ";
}
print "\n";

