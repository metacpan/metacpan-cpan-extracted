#!/usr/local/bin/perl

# Purpose : unit test for Any::Renderer::Template
# Author  : Matt Wilson
# Created : 17th March 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/t/Any_Renderer_Template.t,v 1.10 2006/09/07 14:22:20 johna Exp $

use strict;

#Figure out what to test based on what we have installed
BEGIN {
  use vars qw(%AvailableLanguages $HaveDeps $NumTests);
  $NumTests = 1;
  eval {
    require Any::Template;
    require Cache::AgainstFile;
    $HaveDeps = 1;
    %AvailableLanguages = map {$_ => 1} grep{atb_compiles($_)} @{Any::Template::available_backends()};
    $NumTests += 4;
    $NumTests += 1 if(%AvailableLanguages);
    $NumTests += 5 if($AvailableLanguages{'HTML::Template'});
    $NumTests += 4 if($AvailableLanguages{'IFL::Template'});
    $NumTests += 5 if($AvailableLanguages{'Text::MicroMason'});
  };

  sub atb_compiles {
    my $backend = shift;
    eval {
      new Any::Template({Backend => $backend, String => ""});
    };
    return !$@;
  }
}

use Test::Assertions::TestScript tests => $NumTests, auto_import_trace => 1;
ASSERT(1, "Assessed which templating languages are supported (".join(" ",sort keys %AvailableLanguages).")");

if($HaveDeps) {
  $ENV{ANY_RENDERER_AT_SAFE} = 0;
  require Any::Renderer::Template;
  ASSERT ( 1, "Compiled Any::Renderer::Template version $Any::Renderer::Template::VERSION" );
  
  # are we handling what we _think_ we're handling?
  my %expected = map {$_ => 1} (@{Any::Template::available_backends()},  'Any::Template');
  my @expected_backends = sort keys %expected;
  my @found_backends = sort @{Any::Renderer::Template::available_formats()};
  DUMP(\@expected_backends, \@found_backends);
  ASSERT ( EQUAL (\@expected_backends , \@found_backends), "Handle expected formats" );
  
  # do we require a template as expected (or not)?
  ASSERT ( 1 == Any::Renderer::Template::requires_template ( "HTML::Template" ), "Requires template?" );

  # Trap invalid formats
  ASSERT(DIED(sub {new Any::Renderer::Template( "Nonsense", {} )}) && $@=~/format 'Nonsense'/,"Trap invalid format");  
  
  # HTML::Template
  my $format = "HTML::Template";
  if($AvailableLanguages{$format}) {
    TRACE ( $format );
    
    #In-memory template
    my %options = (
      'TemplateString'  => '<TMPL_VAR NAME=greeting> <TMPL_VAR NAME=entity>!',
    );  
    my $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "HTML::Template in-memory template." );
    
    # HTML::Template file
    %options = (
      'Template'  => 'data/html_template.tmpl',
    );
    
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "HTML::Template file template." );
    
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "HTML::Template file template (w/Cache)." );
    
    $options { 'NoCache' } = 1;
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "HTML::Template file template (w/NoCache)." );
    
    # this should use html_template.tmpl
    %options = (
      "Template"          => "data/html_template.tmpl",
      "TemplateFilename"  => "data/ifl_template.tmpl",
    );
    
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "HTML::Template file template (w/surplus TemplateFilename option)." );
  }
  
  # IFL::Template
  $format = "IFL::Template";
  if($AvailableLanguages{$format}) {
    #Template in memory
    TRACE ( $format );
    my %options = (
      'TemplateString'  => '[INSERT greeting] [INSERT entity]!',
    );
    
    my $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "IFL::Template in-memory template." );
    
    # IFL::Template file
    %options = (
      'Template'  => 'data/ifl_template.tmpl',
    );
    
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "IFL::Template file template." );
    
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "IFL::Template file template (w/Cache)." );
    
    $options { 'NoCache' } = 1;
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "IFL::Template file template (w/NoCache)." );
  }
  
  # Text::MicroMason
  $format = "Text::MicroMason";
  if($AvailableLanguages{$format}) {
    
    #In memory
    TRACE ( $format );
    my %options = (
      'TemplateString'  => '<% $ARGS{greeting} %> <% $ARGS{entity} %>!',
    );
    
    my $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "Text::MicroMason in-memory template." );
    
    # Text::MicroMason file
    %options = (
      'Template'  => 'data/micromason_template.tmpl',
    );
    
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "Text::MicroMason file template." );
    
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "Text::MicroMason file template (w/Cache)." );
    
    # run the same again to test template caching
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "Text::MicroMason file template (w/Cache)." );
    
    $options { 'NoCache' } = 1;
    $renderer = new Any::Renderer::Template ( $format, \%options );
    ASSERT ( "Hello World!\n" eq $renderer->render ( { 'greeting' => 'Hello', 'entity' => 'World' } ), "Text::MicroMason file template (w/NoCache)." );
  }
  
  # finally let's check to make sure an error is throw if no template is provided
  if(%AvailableLanguages) {
    $format = (keys %AvailableLanguages)[0];
    eval
    {
      my $renderer = new Any::Renderer::Template ( $format, {} );
      $renderer->render ( {} );
    };  
    ASSERT ( $@, "No template provided raises error" );
  }
}


# vim: ft=perl
