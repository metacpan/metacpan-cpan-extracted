use strict;
use inc::Module::Install;
name 'AnyEvent-Superfeedr';
all_from 'lib/AnyEvent/Superfeedr.pm';

include('ExtUtils::AutoInstall');
no_index(directory => 't');

requires 'AnyEvent';
requires 'AnyEvent::XMPP';
requires 'XML::Atom';
requires 'Object::Tiny';
requires 'URI::Escape';
requires 'Net::SSLeay';
requires 'Net::LibIDN';
requires 'Scalar::Util';
recommends 'XML::Twig';

githubmeta;

auto_include_deps;
author_tests('xt');
WriteAll;
