#!/bin/bash
# ============================================================================
# Name        : Makefile
# Author      : Juan Lorenzo
# Version     : 0.2
# Copyright   : 
# Description : Makefile for read
# ============================================================================
.PHONY: all clean

#binary folder
SeismicUnixGui_C_BIN = ../bin

# location of code
SeismicUnixGui_C_SRC = ./src

C_COMPILER = gcc

C_FLAGS = -C -ansi -g 
# -Wall

C_OBJ = ../obj

# get math library functions e.g., exp
L_FLAGS = -lm -lc

synseis:
	$(C_COMPILER) $(C_FLAGS) $(SeismicUnixGui_C_SRC)/synseis.c  $(L_FLAGS) -o $(SeismicUnixGui_C_BIN)/synseis 
tbd:
	$(C_COMPILER) $(C_FLAGS) $(SeismicUnixGui_C_SRC)/tbd.c $(L_FLAGS) -o $(SeismicUnixGui_C_BIN)/tbd 
clean:
	rm -f $(C_OBJ)/synseis.o
