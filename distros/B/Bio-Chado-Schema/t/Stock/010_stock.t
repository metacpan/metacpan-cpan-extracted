#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More ;
use Test::Exception;
use Bio::Chado::Schema::Test;
use  Bio::Chado::NaturalDiversity::Reports;

my $schema = Bio::Chado::Schema::Test->init_schema();


isa_ok( $schema, 'DBIx::Class::Schema' );


my $cvterm_rs = $schema->resultset('Cv::Cvterm');
my $stock_rs = $schema->resultset('Stock::Stock');

my $cvterm_name = 'test stock';
my $cv_name = 'test stock';
my $name = 'test stock_name';
my $uniquename = 'unique ' . $name;

$schema->txn_do( sub {
    #create the cvterm for the stock type
    my $cvterm = $cvterm_rs->create_with({ name => $cvterm_name, cv => $cv_name });

    #now create the stock
    my $stock = $stock_rs->create( {
        name => $name,
        uniquename => $uniquename,
        type_id => $cvterm->cvterm_id
                                   } );

    is($stock->name, $name, "stock name test");
    is($stock->uniquename, $uniquename, "stock uniquename test");
    is($stock->type->name, $cvterm_name, "stock type test");

    #create new stockprop
    my $propname = "stockmprop";
    my $value = "value 1";
    my $rank = 3;

    my $href = $stock->create_stockprops({ $propname => $value} , { autocreate => 1, allow_multiple_values => 1 , rank => $rank } );

    my $stockprop = $href->{$propname};
    is($stockprop->value(), $value, "stockmprop value test");
    is($stockprop->rank() , $rank, "stockprop rank test");
    #
    # create stockprop with a literal-sql value
    $propname = "date stockmprop";
    $rank = 1;

    throws_ok {
        $href = $stock->create_stockprops({ $propname =>  \"'ack'"} , { autocreate => 1, allow_multiple_values => 1 , rank => $rank } );
    } qr/allow_duplicate_values/, 'allow_duplicate_values required for prop setting with literal sql';

    $href = $stock->create_stockprops({ $propname =>  \"'ack'"} , { autocreate => 1, allow_multiple_values => 1 , rank => $rank, allow_duplicate_values => 1 } ) ;
        $stockprop = $href->{$propname};
        is($stockprop->value(), 'ack', "stockmprop value test");
        is($stockprop->rank() , $rank, "stockprop rank test");

    #test stock_phenotypes_rs

    #store cvterm id for the observable
        my $obs_name = 'observable term';
        my $obs_cv_name = 'observable_cv';
        my $obs_db_name = 'OBS';
        my $obs_dbxref_acc  = '0000001';
        my $observable = $cvterm_rs->create_with(
            {
                name => $obs_name,
                cv   => $obs_cv_name,
                db   => $obs_db_name,
                dbxref => $obs_dbxref_acc,
            });
        #store a phenotype
        my $phen_value = 'phenotype value';
        my $phenotype = $observable->find_or_create_related('phenotype_observables', {
            uniquename => 'unique phenotype name',
            value      => $phen_value, }  );

        #link the phenotype to the stock
        ###store a new nd_experiment. One experiment per stock
        my $geo_description = 'geo description' ;
        my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create( { description => $geo_description  } );
        my $pheno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
            { name   => 'phenotyping experiment',
              cv     => 'experiment type',
              db     => 'null',
              dbxref => 'phenotyping experiment',
            });
        my $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->create(
            {
                nd_geolocation_id => $geolocation->nd_geolocation_id(),
                type_id => $pheno_cvterm->cvterm_id(),
            } );
        #link to the project
        my $project_name = 'My project name';
        my $project = $schema->resultset("Project::Project")->find_or_create(
            { name => $project_name,
              description => $project_name, } );
        $experiment->find_or_create_related('nd_experiment_projects', {
            project_id => $project->project_id
                                            } );
        #link the experiment to the stock
        $experiment->find_or_create_related('nd_experiment_stocks' , {
            stock_id => $stock->stock_id,
            type_id  =>  $pheno_cvterm->cvterm_id,
                                            });
        # link the phenotype with the experiment
        my $nd_experiment_phenotype = $experiment->find_or_create_related('nd_experiment_phenotypes', { phenotype_id => $phenotype->phenotype_id } );

        # store the unit for the measurement in phenotype_cvterm
        my $unit_name = 'unit name';
        my $unit_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
            { name   => $unit_name });
        $phenotype->find_or_create_related("phenotype_cvterms" , {
            cvterm_id => $unit_cvterm->cvterm_id } ) ;

        my $stock_resultset = $stock_rs->search( { stock_id => $stock->stock_id } );
        my $stock_phenotype_rs = $schema->resultset("Stock::Stock")->stock_phenotypes_rs($stock_resultset) ;
        my $r = $stock_phenotype_rs->next;

        is($r->get_column('stock_id') , $stock->stock_id, "stock_id test");
        is($r->get_column('value'), $phen_value, "phenotpye value test");
        is($r->get_column('observable'),  $obs_name, "observable cvterm name test");
        is($r->get_column('observable_id'),  $observable->cvterm_id, "observable cvterm id test");
        is($r->get_column('unit_name'),  $unit_name, "unit name test");
        is($r->get_column('accession'),  $obs_dbxref_acc, "dbxref accession test");
        is($r->get_column('db_name'),  $obs_db_name, "db name test");
        is($r->get_column('project_description'),  $project_name, "project description test");

        # test the recursive function
        #create first some stock relationships
        my $parent_stock =  $stock_rs->create( {
            name => "parent of $name",
            uniquename => "parent of $uniquename",
            type_id => $cvterm->cvterm_id #a test stock
                                               } );
        my $parent_of = $cvterm_rs->create_with(
            { name   => 'parent_of' });
        $parent_stock->find_or_create_related('stock_relationship_objects', {
            type_id => $parent_of->cvterm_id,
            subject_id => $stock->stock_id,
                                              } );
        my $grandparent_stock = $stock_rs->create( {
            name => "grandparent of $name",
            uniquename => "grandparent of $uniquename",
            type_id => $cvterm->cvterm_id
                                                   } );
        $grandparent_stock->find_or_create_related('stock_relationship_objects', {
            type_id => $parent_of->cvterm_id,
            subject_id => $parent_stock->stock_id,
                                                   } );
        my $test_stock_rs = $stock_rs->search( { stock_id => $grandparent_stock->stock_id } ) ;
        my $results = $schema->resultset("Stock::Stock")->recursive_phenotypes_rs($test_stock_rs, []);
        ok(scalar(@$results) > 0 , "Got recursive phenotypes test");
        foreach my $phen_rs (@$results) {
            while (my $phen =  $phen_rs->next) {
                is($phen->get_column('stock_id') , $stock->stock_id, "stock_id test");
                is($phen->get_column('value'), $phen_value, "phenotpye value test");
                is($phen->get_column('observable'),  $obs_name, "observable cvterm name test");
                is($phen->get_column('observable_id'),  $observable->cvterm_id, "observable cvterm id test");
                is($phen->get_column('unit_name'),  $unit_name, "unit name test");
                is($phen->get_column('accession'),  $obs_dbxref_acc, "dbxref accession test");
                is($phen->get_column('db_name'),  $obs_db_name, "db name test");
                is($phen->get_column('project_description'),  $project_name, "project description test");
            }
        }
        $results = $schema->resultset("Stock::Stock")->recursive_phenotypes_rs($test_stock_rs, []);
        my $report = Bio::Chado::NaturalDiversity::Reports->new;
        my $d = $report->phenotypes_by_trait($results);
        like($d, qr/$obs_name/, 'NaturalDiversity::Reports phenotypes_by_trait test');

        done_testing;
    } );


