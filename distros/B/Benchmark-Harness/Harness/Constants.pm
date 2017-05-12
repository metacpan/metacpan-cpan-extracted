package Benchmark::Harness::Constants;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(HNDLR_ID HNDLR_HARNESS HNDLR_MODIFIERS HNDLR_NAME HNDLR_PACKAGE HNDLR_ORIGMETHOD HNDLR_HANDLED HNDLR_REPORT HNDLR_FILTER HNDLR_FILTERSTART HNDLR_PROCESSIDX);
    use constant {
        HNDLR_ID          =>  0,
        HNDLR_HARNESS     =>  1,
        HNDLR_MODIFIERS   =>  2,
        HNDLR_NAME        =>  3,
        HNDLR_PACKAGE     =>  4,
        HNDLR_ORIGMETHOD  =>  5,
        HNDLR_HANDLED     =>  6,
        HNDLR_REPORT      =>  7,
        HNDLR_FILTER      =>  8,
        HNDLR_FILTERSTART =>  9,
        HNDLR_PROCESSIDX  => 10,  # used by TraceHighRes
    };
1;