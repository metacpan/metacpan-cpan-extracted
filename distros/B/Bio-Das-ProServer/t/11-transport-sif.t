use strict;
use warnings;
use File::Spec;
use Data::Dumper;
use Test::More tests => 20;

my @filenames = &setup_files();

use_ok("Bio::Das::ProServer::SourceAdaptor::Transport::sif");
my $t = Bio::Das::ProServer::SourceAdaptor::Transport::sif->new({
  'config'=>{'filename'=>$filenames[0],'attributes'=>join ';', @filenames[1,2]}
});
isa_ok($t, 'Bio::Das::ProServer::SourceAdaptor::Transport::sif');
can_ok($t, qw(query last_modified DESTROY));
#--------------------------------
my $struct = $t->query({'interactors'=>['nodeA']});
&sort_struct;
my $expected = {
  'interactors'  => [{'id'=>'nodeA'},{'id'=>'nodeB'}],
  'interactions' => [
                     {'name'=>'nodeA-nodeB','participants'=>[{'id'=>'nodeA'},{'id'=>'nodeB'}]},
                    ],
};
is_deeply($struct, $expected, 'single-line binary (source node)') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeB']});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeA'},{'id'=>'nodeB'}],
  'interactions' => [
                     {'name'=>'nodeA-nodeB','participants'=>[{'id'=>'nodeA'},{'id'=>'nodeB'}]},
                    ],
};
is_deeply($struct, $expected, 'single-line binary (target node)') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeC']});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeC'},{'id'=>'nodeD'},{'id'=>'nodeE'}],
  'interactions' => [
                     {'name'=>'nodeC-nodeD','participants'=>[{'id'=>'nodeC'},{'id'=>'nodeD'}]},
                     {'name'=>'nodeC-nodeE','participants'=>[{'id'=>'nodeC'},{'id'=>'nodeE'}]},
                    ],
};
is_deeply($struct, $expected, 'single-line multiple-targets (source node)') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeD']});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeC'},{'id'=>'nodeD'}],
  'interactions' => [
                     {'name'=>'nodeC-nodeD','participants'=>[{'id'=>'nodeC'},{'id'=>'nodeD'}]},
                    ],
};
is_deeply($struct, $expected, 'single-line multiple-targets (target node)') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeE']});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeC'},{'id'=>'nodeE'},{'id'=>'nodeF'},{'id'=>'nodeG'}],
  'interactions' => [
                     {'name'=>'nodeC-nodeE','participants'=>[{'id'=>'nodeC'},{'id'=>'nodeE'}]},
                     {'name'=>'nodeE-nodeF','participants'=>[{'id'=>'nodeE'},{'id'=>'nodeF'}]},
                     {'name'=>'nodeE-nodeG','participants'=>[{'id'=>'nodeE'},{'id'=>'nodeG'}]},
                    ],
};
is_deeply($struct, $expected, 'combining multiple lines') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeH']});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeH'},{'id'=>'nodeI'}],
  'interactions' => [
                     {'name'=>'nodeH-nodeI','participants'=>[{'id'=>'nodeH'},{'id'=>'nodeI'}]},
                    ],
};
is_deeply($struct, $expected, 'duplicated interactions') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeA','nodeC']});
$expected = {
  'interactors'  => [],
  'interactions' => [],
};
is_deeply($struct, $expected, 'non-existing intersection') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeE','nodeG']});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeE'},{'id'=>'nodeG'}],
  'interactions' => [
                     {'name'=>'nodeE-nodeG','participants'=>[{'id'=>'nodeE'},{'id'=>'nodeG'}]},
                    ],
};
is_deeply($struct, $expected, 'multiple-target implied intersection') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeE','nodeG'], 'operation'=>'intersection'});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeE'},{'id'=>'nodeG'}],
  'interactions' => [
                     {'name'=>'nodeE-nodeG','participants'=>[{'id'=>'nodeE'},{'id'=>'nodeG'}]},
                    ],
};
is_deeply($struct, $expected, 'multiple-target explicit intersection') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeC','nodeK'], 'operation'=>'union'});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeC'},{'id'=>'nodeD'},{'id'=>'nodeE'},{'id'=>'nodeJ'},{'id'=>'nodeK'}],
  'interactions' => [
                     {'name'=>'nodeC-nodeD','participants'=>[{'id'=>'nodeC'},{'id'=>'nodeD'}]},
                     {'name'=>'nodeC-nodeE','participants'=>[{'id'=>'nodeC'},{'id'=>'nodeE'}]},
                     {'name'=>'nodeJ-nodeK','participants'=>[{'id'=>'nodeJ'},{'id'=>'nodeK'}]},
                    ],
};
is_deeply($struct, $expected, 'multiple-target union') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeK']});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeJ'},{'id'=>'nodeK'}],
  'interactions' => [
                     {'name'=>'nodeJ-nodeK','participants'=>[{'id'=>'nodeJ'},{'id'=>'nodeK'}]},
                    ],
};
is_deeply($struct, $expected, 'similar node names') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeN','nodeO']});
&sort_struct;
$expected = {
  'interactors'  => [
                     {'id'=>'nodeN','details'=>[{'property'=>'NodeScore','value'=>'1'}]},
                     {'id'=>'nodeO','details'=>[{'property'=>'NodeScore','value'=>'2'}]}
                    ],
  'interactions' => [
                     {'name'=>'nodeN-nodeO','participants'=>[{'id'=>'nodeN'},{'id'=>'nodeO'}]},
                    ],
};
is_deeply($struct, $expected, 'interactor attributes') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({'interactors'=>['nodeQ']});
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeP'},{'id'=>'nodeQ'},{'id'=>'nodeR'}],
  'interactions' => [
                     {
                      'name'        =>'nodeP-nodeQ',
                      'participants'=>[{'id'=>'nodeP'},{'id'=>'nodeQ'}],
                      'details'     =>[{'property'=>'IntScore','value'=>'0.1'}],
                     },
                     {
                      'name'        =>'nodeQ-nodeR',
                      'participants'=>[{'id'=>'nodeQ'},{'id'=>'nodeR'}],
                      'details'     =>[{'property'=>'IntScore','value'=>'0.2'}],
                     },
                    ],
};
is_deeply($struct, $expected, 'interaction attributes') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({
                     'interactors' => ['nodeQ'],
                     'details'     => { 'IntScore' => undef },
                    });
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeP'},{'id'=>'nodeQ'},{'id'=>'nodeR'}],
  'interactions' => [
                     {
                      'name'        =>'nodeP-nodeQ',
                      'participants'=>[{'id'=>'nodeP'},{'id'=>'nodeQ'}],
                      'details'     =>[{'property'=>'IntScore','value'=>'0.1'}],
                     },
                     {
                      'name'        =>'nodeQ-nodeR',
                      'participants'=>[{'id'=>'nodeQ'},{'id'=>'nodeR'}],
                      'details'     =>[{'property'=>'IntScore','value'=>'0.2'}],
                     },
                    ],
};
is_deeply($struct, $expected, 'interaction has attribute') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({
                     'interactors' => ['nodeQ'],
                     'details'     => { 'AnswerToEverything' => undef },
                    });
&sort_struct;
$expected = {
  'interactors'  => [],
  'interactions' => [],
};
is_deeply($struct, $expected, 'interaction does not have attribute') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({
                     'interactors' => ['nodeQ'],
                     'details'     => { 'IntScore' => '0.1' },
                    });
&sort_struct;
$expected = {
  'interactors'  => [{'id'=>'nodeP'},{'id'=>'nodeQ'}],
  'interactions' => [
                     {
                      'name'        =>'nodeP-nodeQ',
                      'participants'=>[{'id'=>'nodeP'},{'id'=>'nodeQ'}],
                      'details'     =>[{'property'=>'IntScore','value'=>'0.1'}],
                     },
                    ],
};
is_deeply($struct, $expected, 'interaction has attribute value') || diag(Dumper($struct));
#--------------------------------
$struct = $t->query({
                     'interactors' =>['nodeQ'],
                     'details'     =>{ 'IntScore'=>'0.3' },
                    });
&sort_struct;
$expected = {
  'interactors'  => [],
  'interactions' => [],
};
is_deeply($struct, $expected, 'interaction does not have attribute value') || diag(Dumper($struct));
#--------------------------------
unlink @filenames;

sub sort_struct {
  $struct->{'interactors'} = [sort {$a->{'id'} cmp $b->{'id'}} @{$struct->{'interactors'}}];
  $struct->{'interactions'} = [sort {$a->{'name'} cmp $b->{'name'}} @{$struct->{'interactions'}}];
  for (my $i=0; $i<@{$struct->{'interactions'}||[]}; $i++) {
    $struct->{'interactions'}[$i]{'participants'} = [sort {$a->{'id'} cmp $b->{'id'}} @{$struct->{'interactions'}[$i]{'participants'}}];
  }
}

sub setup_files {
  my @filenames = map {File::Spec->catfile(File::Spec->tmpdir(), "11-transport-sif-$_.tmp")} qw(int att1 att2);
  my $fh;
  open ($fh, '>', $filenames[0]);
  print $fh q(nodeA pp nodeB
nodeC pp nodeD nodeE
nodeE pp nodeF nodeG
nodeH pp nodeI
nodeH pp nodeI
nodeI pp nodeH
nodeJ pp nodeK
nodeJ pp nodeKK
nodeKK pp nodeL nodeM
nodeL pp nodeM nodeKK
nodeN pp nodeO
nodeP pp nodeQ
nodeQ pp nodeR);
  
  open ($fh, '>', $filenames[1]);
  print $fh q(NodeScore
nodeN = 1
nodeO=2);

  open ($fh, '>', $filenames[2]);
  print $fh q(IntScore
nodeP pp nodeQ = 0.1
nodeQ pp nodeR=0.2);
  close $fh;
  return @filenames;
}
