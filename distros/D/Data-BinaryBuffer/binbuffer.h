#ifndef __BINARY_BUFFER_H__
#define __BINARY_BUFFER_H__

#include <cstring>

#include "binarybuffer-config.h"
#if defined(HAS_ENDIAN_H)
    #include <endian.h>
#elif defined(HAS_SYS_ENDIAN_H)
    #include <sys/endian.h>
#else
    #error Can't find hto* and *toh functions on that system
#endif

#define bb_htobe16(arg) htobe16(arg);
#define bb_htole16(arg) htole16(arg);
#define bb_htobe32(arg) htobe32(arg);
#define bb_htole32(arg) htole32(arg);
#if defined(HAS_ORIGINAL_ENDIAN_MACROS)
#   define bb_be16toh(arg) betoh16(arg);
#   define bb_le16toh(arg) letoh16(arg);
#   define bb_be32toh(arg) betoh32(arg);
#   define bb_le32toh(arg) letoh32(arg);
#else
#   define bb_be16toh(arg) be16toh(arg);
#   define bb_le16toh(arg) le16toh(arg);
#   define bb_be32toh(arg) be32toh(arg);
#   define bb_le32toh(arg) le32toh(arg);
#endif

class BinaryBuffer {
private:
    struct chunk {
        static const int chunk_size = 4096 - sizeof(chunk*) - 2*sizeof(int);
        chunk() : next(NULL), start_off(0), end_off(0) { }

        int data_size() const { return end_off - start_off; }

        chunk* next;
        int    start_off;
        int    end_off;
        uint8_t data[chunk_size];
    };

    chunk* _head;
    chunk* _tail;
    int    _size;

private:
    void add_chunk(chunk* ch) {
        chunk* p = ch;
        _tail->next = p;
        _tail = p;
    }
    chunk* remove_chunk() {
        chunk* p = _head;
        _head = p->next;
        return p;
    }
    int ensure_can_write_to_chunk(int len) {
        if (chunk::chunk_size - _tail->end_off < len) {
            add_chunk(new chunk);
        }
        return chunk::chunk_size - _tail->end_off;
    }
    void remove_empty_chunk() {
        if (_head->start_off == _head->end_off && _head->next) {
            chunk* p = remove_chunk();
            delete p;
        }
    }


public:
    BinaryBuffer() : _head(new chunk), _tail(_head), _size(0) { }
    ~BinaryBuffer() {
        clear();
        delete _head;
    }

    void clear() {
        chunk* tmp = _head->next;
        chunk* n;
        while (tmp != NULL) {
            n = tmp->next;
            delete tmp;
            tmp = n;
        }
        _head->start_off = 0;
        _head->end_off = 0;
        _head->next = NULL;
        _size = 0;
        _tail = _head;
    }

    int size() const { return _size; }

    void write(const char* src, int len) {
        while (len > 0) {
            int free_to_write = ensure_can_write_to_chunk(1);
            int to_write = len > free_to_write ? free_to_write : len;
            memmove(&_tail->data[_tail->end_off], src, to_write);
            _tail->end_off += to_write;
            len -= to_write;
            _size += to_write;
            src += to_write;
        }
    }
    template<typename T> inline T host_to_be(T val);
    template<typename T> inline T host_from_be(T val);
    template<typename T> inline T host_to_le(T val);
    template<typename T> inline T host_from_le(T val);
    template<typename T> inline T host_to_endian(T val);
    template<typename T> inline T host_from_endian(T val);

    template<typename T>
    void write_integral(T val) {
        ensure_can_write_to_chunk(sizeof(T));
        *(T*)(&_tail->data[_tail->start_off]) = host_to_be(val);
        _tail->end_off += sizeof(T);
        _size += sizeof(T);
    }
    template<typename T>
    void write_integral_be(T val) {
        ensure_can_write_to_chunk(sizeof(T));
        *(T*)(&_tail->data[_tail->start_off]) = host_to_be(val);
        _tail->end_off += sizeof(T);
        _size += sizeof(T);
    }
    template<typename T>
    void write_integral_le(T val) {
        ensure_can_write_to_chunk(sizeof(T));
        *(T*)(&_tail->data[_tail->start_off]) = host_to_le(val);
        _tail->end_off += sizeof(T);
        _size += sizeof(T);
    }

    int read(char* buf, int len) {
        if (_size < len)
            len = _size;

        if (len == 0)
            return 0;

        int actual_read_size = 0;

        while (len) {
            int chunk_data_size = _head->data_size();
            int to_read = len > chunk_data_size ? chunk_data_size : len;

            if (to_read > 0) {
                memmove(buf, &_head->data[_head->start_off], to_read);
                buf += to_read;
                _head->start_off += to_read;
                len -= to_read;
                _size -= to_read;
                actual_read_size += to_read;
            }

            remove_empty_chunk();
        }

        return actual_read_size;
    }
    BinaryBuffer* read_buffer(int len) {
        BinaryBuffer* new_buf = new BinaryBuffer();
        if (_size < len)
            len = _size;

        if (len == 0)
            return new_buf;

        while (len) {
            int chunk_data_size = _head->data_size();

            if (len > chunk_data_size) {
                /* then move whole chunk without copy */
                chunk* p = remove_chunk();
                _size -= chunk_data_size;
                p->next = NULL;
                new_buf->add_chunk(p);
                new_buf->_size += chunk_data_size;
                len -= chunk_data_size;
            }
            else { /* copy part of data in last chunk */
                new_buf->ensure_can_write_to_chunk(len);
                memmove(&new_buf->_tail->data[new_buf->_tail->end_off], &_head->data[_head->start_off], len);
                new_buf->_tail->end_off += len;
                new_buf->_size += len;
                _head->start_off += len;
                _size -= len;
                len = 0;
            }
        }

        return new_buf;
    }
    template<typename T>
    T read_integral() {
        T val = *(T*)(&_head->data[_head->start_off]);
        _head->start_off += sizeof(T);
        _size -= sizeof(T);

        remove_empty_chunk();
        return host_from_be(val);
    }
    template<typename T>
    T read_integral_be() {
        T val = *(T*)(&_head->data[_head->start_off]);
        _head->start_off += sizeof(T);
        _size -= sizeof(T);

        remove_empty_chunk();
        return host_from_be(val);
    }
    template<typename T>
    T read_integral_le() {
        T val = *(T*)(&_head->data[_head->start_off]);
        _head->start_off += sizeof(T);
        _size -= sizeof(T);

        remove_empty_chunk();
        return host_from_le(val);
    }
    
};

/* host to big endian specialization */
template<> inline uint8_t BinaryBuffer::host_to_be(uint8_t val) { return val; }
template<> inline int8_t BinaryBuffer::host_to_be(int8_t val) { return val; }
template<> inline uint16_t BinaryBuffer::host_to_be(uint16_t val) { return bb_htobe16(val); }
template<> inline int16_t BinaryBuffer::host_to_be(int16_t val) { return bb_htobe16(val); }
template<> inline uint32_t BinaryBuffer::host_to_be(uint32_t val) { return bb_htobe32(val); }
template<> inline int32_t BinaryBuffer::host_to_be(int32_t val) { return bb_htobe32(val); }

/* big endian to host specialization */
template<> inline uint8_t BinaryBuffer::host_from_be(uint8_t val) { return val; }
template<> inline int8_t BinaryBuffer::host_from_be(int8_t val) { return val; }
template<> inline uint16_t BinaryBuffer::host_from_be(uint16_t val) { return bb_be16toh(val); }
template<> inline int16_t BinaryBuffer::host_from_be(int16_t val) { return bb_be16toh(val); }
template<> inline uint32_t BinaryBuffer::host_from_be(uint32_t val) { return bb_be32toh(val); }
template<> inline int32_t BinaryBuffer::host_from_be(int32_t val) { return bb_be32toh(val); }

/* host to little endian specialization */
template<> inline uint8_t BinaryBuffer::host_to_le(uint8_t val) { return val; }
template<> inline int8_t BinaryBuffer::host_to_le(int8_t val) { return val; }
template<> inline uint16_t BinaryBuffer::host_to_le(uint16_t val) { return bb_htole16(val); }
template<> inline int16_t BinaryBuffer::host_to_le(int16_t val) { return bb_htole16(val); }
template<> inline uint32_t BinaryBuffer::host_to_le(uint32_t val) { return bb_htole32(val); }
template<> inline int32_t BinaryBuffer::host_to_le(int32_t val) { return bb_htole32(val); }

/* little endian to host specialization */
template<> inline uint8_t BinaryBuffer::host_from_le(uint8_t val) { return val; }
template<> inline int8_t BinaryBuffer::host_from_le(int8_t val) { return val; }
template<> inline uint16_t BinaryBuffer::host_from_le(uint16_t val) { return bb_le16toh(val); }
template<> inline int16_t BinaryBuffer::host_from_le(int16_t val) { return bb_le16toh(val); }
template<> inline uint32_t BinaryBuffer::host_from_le(uint32_t val) { return bb_le32toh(val); }
template<> inline int32_t BinaryBuffer::host_from_le(int32_t val) { return bb_le32toh(val); }

#endif /* __BINARY_BUFFER_H__ */
