package Dancer::Template::Ctpp2;

use strict;
use warnings;
use Dancer::Config 'setting';
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';

use base 'Dancer::Template::Abstract';

our $VERSION = '0.02';

our $_ctpp2;
our %_cfg;

sub default_tmpl_ext {
  return ($_cfg{'use_bytecode'}) ? 'ct2' : 'tmpl';
}


sub init {
    my ($self) = @_;

    die "HTML::CTPP2 is needed by Dancer::Template::Ctpp2"
      unless Dancer::ModuleLoader->load('HTML::CTPP2');
    
    %_cfg=%{$self->config};
    my $use_bytecode = (defined $_cfg{'compiled'}) ? delete $_cfg{'compiled'} : 0;

    $_ctpp2 = new HTML::CTPP2(
	arg_stack_size      => 1024,
	code_stack_size     => 1024,
	steps_limit         => 1024*1024,
	max_functions       => 1024,
	%_cfg,
    );
    
    $_cfg{'use_bytecode'} = $use_bytecode;
}

sub render($$$) {
    my ($self, $template, $tokens) = @_;

    die "'$template' is not a regular file"
      if !ref($template) && (!-f $template);

    my $b;

    if ($_cfg{'use_bytecode'}) {
        $b = $_ctpp2->load_bytecode($template);
    } else {
        $b = $_ctpp2->parse_template($template);
    }

    $_ctpp2->reset();
    $_ctpp2->param($tokens);

    my $result  = $_ctpp2->output($b);
    
    if(length(setting('charset')) && lc setting('charset') eq 'utf-8') {
      return pack "U0C*", unpack "C*", $result;    
    } else {
      return $result;  
    }
    
}

1;
__END__

=pod

=head1 NAME

Dancer::Template::Ctpp2 - HTML::CTPP2 wrapper for Dancer

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<HTML::CTPP2> module.

This template engine is much (22 -25 times) faster than others and contains extra functionality.

In order to use this engine, use the template setting:

    template: ctpp2

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

Since HTML::CTPP2 uses different syntax to other template engines like
Template::Toolkit, for current Dancer versions the default layout B<main.tmpl> will
need to be updated, changing the C<[% content %]> line to:

    <TMPL_var content>
    
Future versions of Dancer may ask you which template engine you wish to use, and
write the default layout appropriately.
    
By default, Dancer configures HTML::CTPP2 engine to parse templates from source code
(template filenames with .tmpl extension) instead of compiled templates.
This can be changed within your config file - for example:
    
    template: ctpp2
        engines:
            ctpp2:
                compiled: 1
                source_charset: 'CP1251'
                destination_charset: 'utf-8'
                                                        
Compiled template filenames should end with .ct2.
                                                        
C<source_charset> and C<destination_charset> settings are used for on-the-fly 
charset converting of template output. These settings are optional.

=head1 SEE ALSO

L<Dancer>, L<HTML::CTPP2>

=head1 AUTHOR
 
Maxim Nikolenko, C<< <mephist@cpan.org> >>
 
=head1 SUPPORT

You cat find documentation for CTPP2 library at:

L<http://ctpp.havoc.ru/en/index.html> - in English
L<http://ctpp.havoc.ru/index.html> - in Russian

=head1 CONTRIBUTING
 
This module is developed on Github at:                                                          
 
L<http://github.com/mephist/Dancer-Template-CTPP>
 
Feel free to fork the repo and submit pull requests!

=head1 LICENSE

This module is free software and released under the same terms as CTPP2 
library itself.

  Copyright (c) 2006 - 2009 CTPP Team

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:
  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.
  4. Neither the name of the CTPP Team nor the names of its contributors
     may be used to endorse or promote products derived from this software
     without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
  SUCH DAMAGE.

=cut
