#!perl -T

use Test::More tests => 27;

BEGIN {
	use_ok( 'App::Toodledo' );
	use_ok( 'App::Toodledo::Goal' );
	use_ok( 'App::Toodledo::LocationRole' );
	use_ok( 'App::Toodledo::Folder' );
	use_ok( 'App::Toodledo::TaskCache' );
	use_ok( 'App::Toodledo::AccountInternal' );
	use_ok( 'App::Toodledo::TaskRole' );
	use_ok( 'App::Toodledo::LocationInternal' );
	use_ok( 'App::Toodledo::NotebookInternal' );
	use_ok( 'App::Toodledo::AccountRole' );
	use_ok( 'App::Toodledo::GoalRole' );
	use_ok( 'App::Toodledo::InternalWrapper' );
	use_ok( 'App::Toodledo::Notebook' );
	use_ok( 'App::Toodledo::FolderInternal' );
	use_ok( 'App::Toodledo::GoalInternal' );
	use_ok( 'App::Toodledo::InfoCache' );
	use_ok( 'App::Toodledo::ContextInternal' );
	use_ok( 'App::Toodledo::NotebookRole' );
	use_ok( 'App::Toodledo::Context' );
	use_ok( 'App::Toodledo::TokenCache' );
	use_ok( 'App::Toodledo::Account' );
	use_ok( 'App::Toodledo::Task' );
	use_ok( 'App::Toodledo::FolderRole' );
	use_ok( 'App::Toodledo::Location' );
	use_ok( 'App::Toodledo::ContextRole' );
	use_ok( 'App::Toodledo::Util' );
	use_ok( 'App::Toodledo::TaskInternal' );
}
