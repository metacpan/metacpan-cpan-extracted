#!/bin/bash

dzil build;
cd AI-ML-0.001;
perl Build.PL --with-double;
./Build
./Build test
