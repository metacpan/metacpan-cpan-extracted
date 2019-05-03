#ifndef __BINARY_BUFFER_H__
#define __BINARY_BUFFER_H__

#include <cstring>

#include <boost/endian/conversion.hpp>

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

    template<typename T>
    void write_integral(T val) {
        ensure_can_write_to_chunk(sizeof(T));
        *(T*)(&_tail->data[_tail->start_off]) = boost::endian::native_to_big(val);
        _tail->end_off += sizeof(T);
        _size += sizeof(T);
    }
    template<typename T>
    void write_integral_be(T val) {
        ensure_can_write_to_chunk(sizeof(T));
        *(T*)(&_tail->data[_tail->start_off]) = boost::endian::native_to_big(val);
        _tail->end_off += sizeof(T);
        _size += sizeof(T);
    }
    template<typename T>
    void write_integral_le(T val) {
        ensure_can_write_to_chunk(sizeof(T));
        *(T*)(&_tail->data[_tail->start_off]) = boost::endian::native_to_little(val);
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
        return boost::endian::big_to_native(val);
    }
    template<typename T>
    T read_integral_be() {
        T val = *(T*)(&_head->data[_head->start_off]);
        _head->start_off += sizeof(T);
        _size -= sizeof(T);

        remove_empty_chunk();
        return boost::endian::big_to_native(val);
    }
    template<typename T>
    T read_integral_le() {
        T val = *(T*)(&_head->data[_head->start_off]);
        _head->start_off += sizeof(T);
        _size -= sizeof(T);

        remove_empty_chunk();
        return boost::endian::little_to_native(val);
    }
    
};

#endif /* __BINARY_BUFFER_H__ */
