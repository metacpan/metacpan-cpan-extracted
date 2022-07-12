# source ~/emsdk/emsdk_env.sh
CC:=emcc
SRCDIR?=src
MINIAUDIODIR?=deps/miniaudio
DRFLACDIR?=deps/dr_libs
OUTDIR?=bin
TARGET:=$(OUTDIR)/_mhfscl.js

CFLAGS:=-Wall -Wextra -Werror -I$(DRFLACDIR) -I$(MINIAUDIODIR) -DMA_NO_DEVICE_IO -DMA_NO_THREADING -DMA_NO_ENCODING -DDR_FLAC_BUFFER_SIZE=65536 -DDR_FLAC_NO_OGG -s'EXPORTED_RUNTIME_METHODS=["cwrap", "ccall"]' -s'EXPORTED_FUNCTIONS=["_malloc", "_realloc"]' -s'EXTRA_EXPORTED_RUNTIME_METHODS=["UTF8ToString", "addFunction", "removeFunction", "allocateUTF8"]' -sEXPORT_ES6=1 -sASSERTIONS=1 -sALLOW_MEMORY_GROWTH=1 -sMODULARIZE=1 -sALLOW_TABLE_GROWTH=1

all: CFLAGS += -O3
all: $(TARGET)

$(TARGET): $(SRCDIR)/mhfs_cl.c $(DRFLACDIR)/dr_flac.h $(MINIAUDIODIR)/miniaudio.h $(SRCDIR)/blockvf.h $(SRCDIR)/mhfs_cl_track.h $(SRCDIR)/mhfs_cl_decoder.h $(SRCDIR)/exposetype.h $(SRCDIR)/mhfs_cl_misc.h $(SRCDIR)/mhfs_cl.h
	mkdir -p $(OUTDIR)
	$(CC) $(CFLAGS) -o $@ $<

debug: CFLAGS += -O0 -g4 --source-map-base ./ -s SAFE_HEAP=1 -DMHFSCLTR_PRINT_ON=1 -DMHFSCLDEC_PRINT_ON=1
debug: $(TARGET)
#rsync -a $(SRCDIR) $(OUTDIR)/
#cp $(MINIAUDIODIR)/miniaudio.h $(OUTDIR)/src/
#cat $(OUTDIR)/_mhfscl.wasm.map | sed -e 's|$(MINIAUDIODIR)/miniaudio.h|src/miniaudio.h|' > $(OUTDIR)/src/_mhfscl.wasm.map

fulldbg: CFLAGS += -DBLOCKVF_PRINT_ON=1
fulldbg: debug

clean:
	rm -rf $(OUTDIR)/*

.PHONY: debug clean fulldbg
