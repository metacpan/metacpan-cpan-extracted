use strict;
use Test::More;
use File::Path qw( remove_tree );

plan skip_all => 'Cannot read bin/sibs' unless -x 'bin/sibs';

$ENV{HOME} = 't/home';
my $script = do 'bin/sibs' or die $@;

{
  $script->{silent} = !$ENV{HARNESS_IS_VERBOSE};
  remove_tree 't/home/.ssh' if -d 't/home/.ssh';
}

{
  $main::SSH_KEYGEN = 't/bin/ssh-keygen';
  open my $SSH_KEYGEN, '>', $main::SSH_KEYGEN or die $!;
  print $SSH_KEYGEN "#!$^X\n";
  print $SSH_KEYGEN "open my \$FH, '>', pop(\@ARGV) .'.pub';\n";
  print $SSH_KEYGEN "print \$FH join ',', \@ARGV;\n";
  print $SSH_KEYGEN "print \$FH qq(\\n);";
  chmod 0755, $main::SSH_KEYGEN;
}

{
  $main::SSH = 't/bin/ssh';
  open my $SSH, '>', $main::SSH or die $!;
  print $SSH "#!$^X\n";
  print $SSH "open my \$FH, '>', 't/bin/ssh.out';\n";
  print $SSH "print \$FH \$_ while <STDIN>;\n";
  print $SSH "print \$FH join ',', \@ARGV;\n";
  print $SSH "print \$FH qq(\\n);";
  chmod 0755, $main::SSH;
}

{
  $script->{destination} = URI->new('rsync://bruce@localhost');
  $script->create_identity_file;
  open my $FH, '<', 't/home/.ssh/sibs_dsa.pub';
  is readline($FH), "-q,-b,4096,-t,rsa,-N,,-f\n", 'ran ssk-keygen';
}

{
  open my $FH, '<', 't/bin/ssh.out';
  while(<$FH>) { /^__DATA__/ and last }
  is readline($FH) || '', "-q,-b,4096,-t,rsa,-N,,-f\n", 'ran ssk with data';
  my $expected = "-l,bruce,sibs-localhost,perl - remote-init\n";
  $expected =~ s/ - / - --silent / unless $ENV{HARNESS_IS_VERBOSE};
  is readline($FH) || '', $expected, 'ran ssh with options';
}

{
  $script->remote_add_pub_key("some pub key user\@foo\n");
  open my $FH, '<', 't/home/.ssh/authorized_keys';
  is readline($FH), "some pub key user\@foo\n", 'add pub key remote';
  my $size = -s 't/home/.ssh/authorized_keys';

  $script->remote_add_pub_key("some pub key user\@foo\n");
  is -s 't/home/.ssh/authorized_keys', $size, 'got same size second time around';
}

done_testing;
