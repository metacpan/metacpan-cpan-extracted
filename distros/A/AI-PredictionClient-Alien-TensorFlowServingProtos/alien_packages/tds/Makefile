# Makefile to compile protofiles into a TensorFlow Serving client library.
# 20170712 Tom Stall

HOST_SYSTEM = $(shell uname | cut -f 1 -d_)
SYSTEM ?= $(HOST_SYSTEM)
CXX = g++
CPPFLAGS += -I/usr/local/include -I./ -pthread -fPIC
CXXFLAGS += -std=c++11
ifeq ($(SYSTEM),Darwin)
LDFLAGS += -L/usr/local/lib `pkg-config --libs grpc++ grpc`       \
           -lgrpc++_reflection \
           -lprotobuf -lpthread -ldl
else
LDFLAGS += -L/usr/local/lib `pkg-config --libs grpc++ `       \
            -lprotobuf 
endif
SLDFLAGS += -L/usr/local/lib `pkg-config --libs grpc++ grpc`       \
           -Wl,--no-as-needed -lgrpc++_reflection -Wl,--as-needed \
           -lprotobuf -lpthread -lssl -lcrypto -lz -ldl

PROTOC_CMD = protoc

GRPC_CPP_PLUGIN = grpc_cpp_plugin
GRPC_CPP_PLUGIN_PATH ?= `which $(GRPC_CPP_PLUGIN)`

PROTOS_PATH = .

vpath %.proto $(PROTOS_PATH)

PREFIX = $(prefix)

SOURCES := $(shell find $(SOURCEDIR) -name '*.proto')
OBJECTS = $(patsubst %.proto, %.pb.o, $(SOURCES))
CPP_GEN  = $(patsubst %.proto, %.pb.cc, $(SOURCES))

all: tensorflow_serving_protos_cc_gen tensorflow_serving_protos_so 

tensorflow_serving_protos_cc_gen: $(CPP_GEN) tensorflow_serving/apis/prediction_service.grpc.pb.cc
 
tensorflow_serving_protos_so: $(OBJECTS) tensorflow_serving/apis/prediction_service.grpc.pb.o 
	$(CXX) $^ -shared $(LDFLAGS) -o lib$@.so

.PHONY: install
install: libtensorflow_serving_protos_so.so
	mkdir -p $(PREFIX)/lib
	mkdir -p $(PREFIX)/include
	cp libtensorflow_serving_protos_so.so $(PREFIX)/lib/
	cp -r tensorflow  $(PREFIX)/include/
	cp -r tensorflow_serving  $(PREFIX)/include/
	cp  -r tds  $(PREFIX)/include/

.PRECIOUS: %.grpc.pb.cc
%.grpc.pb.cc: %.proto
	$(PROTOC_CMD) -I $(PROTOS_PATH) --grpc_out=. --plugin=protoc-gen-grpc=$(GRPC_CPP_PLUGIN_PATH) $<

.PRECIOUS: %.pb.cc
%.pb.cc: %.proto
	$(PROTOC_CMD) -I $(PROTOS_PATH) --cpp_out=. $<

