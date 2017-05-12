#!/bin/bash
/opt/mpich-2.1/bin/mpiexec -machinefile ${machinefile} -n ${nbmachines} /usr/local/bin/mpibasictest
