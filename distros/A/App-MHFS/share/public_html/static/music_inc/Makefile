# source ~/emsdk/emsdk_env.sh
CC:=emcc
SRCDIR?=src
OUTDIR?=.
TARGET:=$(OUTDIR)/drflac.js

CFLAGS:=-s 'EXPORTED_FUNCTIONS=["_network_drflac_open_mem", "_network_drflac_read_pcm_frames_f32_mem", "_network_drflac_close", \
"_network_drflac_totalPCMFrameCount", "_network_drflac_sampleRate", "_network_drflac_bitsPerSample", "_network_drflac_channels", \
"_network_drflac_mem_create", "_network_drflac_mem_free", "_network_drflac_mem_add_block", "_network_drflac_mem_bufptr", \
"_network_drflac_create_error", "_network_drflac_free_error", "_network_drflac_error_code", "_network_drflac_extra_data"]'
CFLAGS += -s 'EXPORTED_RUNTIME_METHODS=["cwrap", "ccall"]'
CFLAGS += -s 'EXPORT_ES6=1'
CFLAGS += -s 'ASSERTIONS=1'
CFLAGS += -s 'ALLOW_MEMORY_GROWTH=1'
CFLAGS += -s 'MODULARIZE=1'

all: CFLAGS += -O3
all: $(TARGET)

$(TARGET): $(SRCDIR)/drflac_cache.c
	$(CC) $(CFLAGS) -o $@ $^

debug: CFLAGS += -O0 -g4 --source-map-base ./src/ -s SAFE_HEAP=1
debug: $(TARGET)
	rsync -a $(SRCDIR) $(OUTDIR)/
	cp $(OUTDIR)/drflac.wasm.map $(OUTDIR)/src/drflac.wasm.map

clean:
	rm -f drflac.js drflac.wasm drflac.wasm.map src/drflac.wasm.map

.PHONY: debug clean
