CC=g++
CFLAGS=-O2 -pipe -Wall
EXE=ann_compute


run: $(EXE) pso_ann.pl
	perl pso_ann.pl

$(EXE): NeuralNet.o main.o
	$(CC) -o $(EXE) main.o NeuralNet.o

main.o: main.cpp NeuralNet.h
	$(CC) $(CFLAGS) -c main.cpp

NeuralNet.o: NeuralNet.h NeuralNet.cpp
	$(CC) $(CFLAGS) -c NeuralNet.cpp

clean:
	rm -f *.o $(EXE) 

.PHONY : clean
