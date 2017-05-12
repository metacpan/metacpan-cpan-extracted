#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use ASP4::ConfigLoader;
my $config; BEGIN { $config = ASP4::ConfigLoader->load }

use HTML::Form;

use_ok('ASP4::UserAgent');

my $ua = ASP4::UserAgent->new();

TEST1: {
  my $res = $ua->get('/useragent/hello-world.asp');
  is( $res->content, "Hello, World!\n"x5 . "\n", "hello-word.asp is correct" );
};

TEST2: {
  my $res = $ua->get('/useragent/simple-args.asp?color=red');
  is( $res->content, "Your favorite color is red!\n", "simple-args.asp is correct" );
};

TEST3: {
  my $res = $ua->post('/useragent/simple-args.asp?color=red');
  is( $res->content, "Your favorite color is red!\n", "simple-args.asp is correct" );
};

TEST4: {
  my $res = $ua->post('/useragent/simple-args.asp', {
    color => 'red'
  });
  is( $res->content, "Your favorite color is red!\n", "simple-args.asp is correct" );
};

TEST5: {
  my $res = $ua->post('/useragent/simple-args.asp', [
    color => 'red'
  ]);
  is( $res->content, "Your favorite color is red!\n", "simple-args.asp is correct" );
};

TEST6: {
  my $res = $ua->get('/useragent/simple-form.asp');
  my ($form) = HTML::Form->parse( $res->content, '/' );
  ok( $form, 'found form' );
  $form->find_input('color')->value('Red');
  $form->find_input('pet_name')->value('Fluffy');
  $res = $ua->submit_form( $form );
  ($form) = HTML::Form->parse( $res->content, '/' );
  ok( $form, 'found form again!' );
  is( $form->find_input('color')->value => 'Red', 'color is Red' );
  is( $form->find_input('pet_name')->value => 'Fluffy', 'pet_name is Fluffy' );
};

TEST7: {
  my $res = $ua->get('/useragent/upload-form.asp');
  my ($form) = HTML::Form->parse( $res->content, '/' );
  ok( $form, 'found form' );
  
  my $filename = ( $ENV{TEMP} || $ENV{TMP} || '/tmp' ) . '/' . rand() . '.txt';
  open my $ofh, '>', $filename
    or die "Cannot open '$filename' for writing: $!";
  my $data = join "\n", map {
    "$_: " . rand()
  } 1..100;
  print $ofh $data;
  close($ofh);
  open my $ifh, '<', $filename
    or die "Cannot open '$filename' for reading: $!";
  
  $form->find_input('filename')->value( $filename );
  $res = $ua->submit_form( $form );
  ($form) = HTML::Form->parse( $res->content, '/' );
  is(
    $form->find_input('file_contents')->value => $data,
    "File upload successful"
  );
  unlink($filename);
};

TEST8: {
  my $filename = ( $ENV{TEMP} || $ENV{TMP} || '/tmp' ) . '/' . rand() . '.txt';
  open my $ofh, '>', $filename
    or die "Cannot open '$filename' for writing: $!";
  my $data = join "\n", map {
    "$_: " . rand()
  } 1..100;
  print $ofh $data;
  close($ofh);
  open my $ifh, '<', $filename
    or die "Cannot open '$filename' for reading: $!";
  
  my $res = $ua->upload('/useragent/upload-form.asp', [
    filename  => [$filename]
  ]);
  
  my ($form) = HTML::Form->parse( $res->content, '/' );
  is(
    $form->find_input('file_contents')->value => $data,
    "File upload successful"
  );
  unlink($filename);
};

TEST9: {
  my $res = $ua->get('/masters/deep.asp');
  my $expected = q(<html>
  <head>
    <title>
      My Title!
    </title>
    <meta name="keywords" content="submaster keywords" />
    <meta name="description" content="submaster description" />
  </head>
  <body>
    <h1>
      The Submaster Page
    </h1>
    <p>
      
  The first part.<br/>
  My Content Too!
  The final part.

    </p>
  </body>
</html>

);
  is(
    $res->content, $expected, "/masters/deep.asp is correct"
  );
};


